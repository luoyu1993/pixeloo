//
//  CanvasVIew.swift
//  pixeloo
//
//  Created by hata on 2019/4/16.
//  Copyright © 2019 hata. All rights reserved.
//

import Foundation
import SpriteKit

class CanvasView : SKView{
    
    var c_size : CancasSize!
    var canvasScene: SKScene!
    var sprite :SKSpriteNode!
    
    // 画布中的所有UI像素对象
    var pixelArray = [[Pixel]]()
    
    // 画布中的点
    var points = [[Point]]()
    
    // 历史数据
    var history = [[[Point]]]()
    var his_index = 0
    
    var savedelegate : SaveToApp?
    
    init(frame: CGRect, c_size:CancasSize) {
        super.init(frame: frame)
        self.c_size = c_size
        
        sprite = SKSpriteNode()
        let sprite_w = CGFloat(PIXEL_SIZE * c_size.width)
        let sprite_h = CGFloat(PIXEL_SIZE * c_size.height)
        
        canvasScene = SKScene( size: CGSize(width: sprite_w ,height: sprite_h))
        presentScene(canvasScene)
        
        sprite.position = CGPoint(x: 0, y: 0)
        sprite.size = CGSize(width: sprite_w, height: sprite_h)
        
        canvasScene.addChild(sprite)

        //  创建 size 个sksprite
        for h in 0..<c_size.height {
            
            var tmp = [Pixel]()
            var tmp_points = [Point]()
            for w in 0..<c_size.width {
                let pixel = Pixel()
                
                pixel.name = String.init(format: "%d_%d", w,h)
                pixel.position = CGPoint(x: w * 16, y: h * 16)
                tmp.append(pixel)
                
                sprite.addChild(pixel)
                tmp_points.append(Point(x:w, y:h, color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
            }
            
            pixelArray.append(tmp)
            points.append(tmp_points)
        }
        history.append(points)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        for touch in touches {
            handleTouch(touch: touch, type : 0)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouch(touch: touch , type : 1)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tmp_pos = nil
        points = history[his_index]
        ShowWithPoints(points: points)
    }
 
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tmp_pos = nil
        
        let need_delete = history.count - his_index - 1
        
        if need_delete > 0 {
            for _ in 1...need_delete {
                history.removeLast()
            }
        }
        
        history.append(points)
        his_index = history.count - 1
    }
    
    var tmp_pos : CGPoint!
    
    func handleTouch(touch : UITouch, type : Int) {
        
        var tar_color = palette_color
        
        switch pen_type {
        case .pencil:
            tar_color = palette_color
        case .eraser:
            tar_color = UIColor.white
        default:
            tar_color = palette_color
        }
        
        var poses : [Point]
        
        if type != 0 {
            poses = caculateoo(pointx: tmp_pos,pointy: touch.location(in: sprite))
        }else{
            let pos = Point(cgpoint: touch.location(in: sprite))
            poses = [Point]()
            poses.append(pos)
        }
        
        tmp_pos = touch.location(in: sprite)
        
        for pos in poses {
            if pos.y > c_size.height - 1  ||  pos.y < 0 {
                continue
            }
            
            if  pos.x < 0 ||  pos.x > c_size.width - 1 {
                continue
            }
            
            pixelArray[pos.y][pos.x].fillColor = tar_color
            points[pos.y][pos.x].color = tar_color
        }
    }
    
    // 填补两点间的像素点
    func caculateoo(pointx : CGPoint, pointy : CGPoint ) -> [Point]  {
        var poss = [Point]()
        
        let p_a = Point(cgpoint: pointx)
        let p_b = Point(cgpoint: pointy)
        poss.append(p_a)
        poss.append(p_b)
        
        let dis = p_a.distance(q: p_b)
        if dis >= 2 {
            let tmp = CGPoint(x: (pointx.x - pointy.x) / CGFloat(dis) ,y: (pointx.y - pointy.y) / CGFloat(dis))
            
            for idx in 1..<dis {
                let tmp_pos = CGPoint(x: pointy.x + tmp.x * CGFloat(idx),y: pointy.y + tmp.y * CGFloat(idx))
                let p_t = Point(cgpoint: tmp_pos)
                poss.append(p_t)
            }
        }
        
        return poss
    }
    
    func back() {
        if his_index <= 0 {
            return
        }
        
        his_index = his_index - 1
        
        points = history[his_index]
        
        ShowWithPoints(points: points)
    }
    
    func forward() {
        if his_index == history.count - 1 {
            return
        }
    
        his_index = his_index + 1
        
        points = history[his_index]
        
        ShowWithPoints(points: points)
    }
    
    
    func ShowWithPoints(points:[[Point]]) {
        
        for pp in points {
            for p in pp {
             pixelArray[p.y][p.x].fillColor = p.color
            }
        }
    }
    
    func getcanvasImage() -> UIImage? {
        let exporter = PictureExporter(colorArray: GetColorArray(), canvasWidth: c_size.width, canvasHeight: c_size.height)
        return exporter.generateThumbnailFromDrawing()
    }
    
    func save() -> Bool{
        guard let imagedata = getcanvasImage() else {
            print("export error")
            return false
        }

        var recoders = [[[UIColor]]]()
        for c in history {
            var r_c = [[UIColor]]()
            for l in c {
                var r_l = [UIColor]()
                for p in l {
                    r_l.append(p.color)
                }
                r_c.append(r_l)
            }
            recoders.append(r_c)
        }
        let c = CanvasData()
        
        c.width = Int64(c_size.width)
        c.height = Int64(c_size.height)
        c.palette_colors = palette.colors
        c.historys = recoders
        c.imagedata = NSData(data: imagedata.pngData()!)
        
        savedelegate?.SaveToApp(data: c)
        
        return true
    }
    
    func GetColorArray() -> [UIColor] {
        var colors = [UIColor]()
        var tmp_a = points
        tmp_a.reverse()
        for ps in tmp_a {
            for p in ps {
                colors.append(p.color)
            }
        }
        return colors
    }
    
    func LoadViewWith(data:CanvasData) {
        
        if data.historys == nil {
            var tmp_p = [[Point]]()
            for h in 0..<c_size.height {
                var tmp_points = [Point]()
                for w in 0..<c_size.width {
                    tmp_points.append(Point(x:w, y:h, color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                }
                tmp_p.append(tmp_points)
            }
            history.append(tmp_p)
        }else{
            history = [[[Point]]]()
            for z in 0..<data.historys!.count {
                var his = [[Point]]()
                for y in 0..<data.historys![z].count {
                    var hi = [Point]()
                    for x in 0..<data.historys![z][y].count {
                        let i = Point(x: x, y: y, color: data.historys![z][y][x])
                        hi.append(i)
                    }
                    his.append(hi)
                }
                history.append(his)
            }
        }
 
        his_index = history.count - 1
        points = history[his_index]
        
        ShowWithPoints(points: points)
    }
}

public struct CancasSize {
    var width : Int = 0
    var height : Int = 0
}

protocol SaveToApp {
    func SaveToApp(data:CanvasData)
}
