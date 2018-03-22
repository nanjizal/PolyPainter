package;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Color;
import polyPainter.PolyPainter;

class Main {
    static var poly:   PolyPainter;
    static var canvas: kha.Image;
    static function update(): Void {}
    static function render( framebuffer: Framebuffer ): Void {
        // draw directly on framebuffer
        var g2 = framebuffer.g2;
        poly.framebuffer = framebuffer;    
        poly.begin( true );
        poly.drawGradientTriangle( 0, 0, 30, 10, 50, 400, Color.Red, Color.Green, Color.Blue );
        poly.drawImageTriangle( 30, 10, 300, 10, 50, 400, 0, 0, 1, 0, 0, 1, kha.Assets.images.suma );
        poly.end();
        // draw on a canvas
        poly.canvas = canvas;
        poly.begin(true);
        poly.drawImageTriangle( 10, 10, 300, 10, 50, 400, 0, 0, 1, 0, 0, 1, kha.Assets.images.pexel );
        poly.drawGradientTriangle( 210, 10, 300, 10, 50, 400, Color.Red, Color.Green, Color.Blue );
        poly.end();
        // draw canvas on framebuffer
        g2.begin(false);
        g2.drawImage( canvas,100,0);
        g2.end();
    }
    static function onLoaded(){
        Scheduler.addTimeTask( function () { update(); }, 0, 1 / 60);
        System.notifyOnRender( function ( framebuffer ) { render( framebuffer ); } );
    }
    public static function main() {
        System.init({title: "PolyPainter Example", width: 800, height: 600 }, function() {
            // Avoid passing update/render directly so replacing
            // them via code injection works
            canvas = kha.Image.createRenderTarget( 1024, 768, null, kha.graphics4.DepthStencilFormat.NoDepthAndStencil );
            poly = new PolyPainter();
            kha.Assets.loadEverything( onLoaded );
        });
    }
}
