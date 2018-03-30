package;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Color;
import polyPainter.PolyPainter;
import kha.graphics4.TextureAddressing;
class Main {
    static var polyPainter:   PolyPainter;
    static var renderTarget: kha.Image;
    static function update(): Void {
        Scheduler.stop();
        // draw on an Image
        polyPainter.canvas = renderTarget;
        polyPainter.begin( false );
        sky();
        polyPainter.end();
    }
    static function render( framebuffer: Framebuffer ): Void {
        // draw directly on framebuffer
        var g2 = framebuffer.g2;
        polyPainter.framebuffer = framebuffer;    
        polyPainter.begin( true );
        polyPainter.drawImageTriangle( 0, 0, 1000, 0, 1000, 1000, 0, 0, 1, 0, 1, 1, renderTarget );
        polyPainter.drawImageTriangle( 0, 0, 1000, 1000, 0, 1000, 0, 0, 1, 1, 0, 1, renderTarget );
        polyPainter.end();
        System.removeRenderListener( render );
    }
    // Uses some gradient triangles to create an interesting sky using bit of red and green on either sides.
    static inline function sky(){
        var blueRed = 0xFF6F73F3;//blueWithBitOfRed
        var blueGreen = 0xFFB0EaF5;//blueWithBitOfGreen
        var topUp = -200;// cheat moved top up to soften the darkest blue, rather than tweaking all colors.
        polyPainter.drawGradientTriangle( 0, topUp, 400, topUp, 0, 400, blueRed, 0xFF4F78EE, 0xFFAECFF5 );
        polyPainter.drawGradientTriangle( 0, 400, 400, topUp, 400, 400, 0xFFAECFF5, 0xFF4F78EE, 0xFF8CA9EE );
        polyPainter.drawGradientTriangle( 400, topUp, 800, topUp, 400, 400, 0xFF4F78EE, 0xFF1D5FEC, 0xFF8CA9EE );
        polyPainter.drawGradientTriangle( 400, 400, 800, topUp, 800, 400, 0xFF8CA9EE, 0xFF1D5FEC, blueGreen );
    }
    static function onLoaded(){
        Scheduler.addTimeTask( function () { update(); }, 0, 1 / 60);
        System.notifyOnRender( function ( framebuffer ) { render( framebuffer ); } );
    }
    public static function main() {
        System.init({title: "PolyPainter Example", width: 800, height: 600 }, function() {
            // Avoid passing update/render directly so replacing
            // them via code injection works
            renderTarget = kha.Image.createRenderTarget( 1024, 768, null, kha.graphics4.DepthStencilFormat.NoDepthAndStencil );
            polyPainter = new PolyPainter();
            polyPainter.textureAddressingX = Repeat;
            polyPainter.textureAddressingY = Repeat;
            kha.Assets.loadEverything( onLoaded );
        });
    }
}
