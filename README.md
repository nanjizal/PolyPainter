# PolyPainter
PolyPainter class to allow you to draw textured and gradient triangles in Kha more easily.

#### Notes:
- Thanks to Sidar for initial version - from which this is modified and extended. And for the lovely Rose img hope it's ok to use?
- Subject to change when explored real use cases.

## Usage:

### Setup

To setup the shaders by creating a new 'PolyPainter'

``` Haxe
	polyPainter = new PolyPainter();
```

### Setting drawing target

There are two options for where you draw:

- on Framebuffer in the render loop.

``` Haxe
	    polyPainter.framebuffer = framebuffer; 
```

- on an Image ( Canvas )

``` Haxe
        var image = kha.Image.createRenderTarget( 1024, 768, null, kha.graphics4.DepthStencilFormat.NoDepthAndStencil );
	    polyPainter.canvas = image;
```

    

### Drawing triangles

There several options for drawing your triangles but they must have a **begin** and **end** before use and a target already setup.

``` Haxe
        polyPainter.begin( true );
        // draw your triangles here...
        polyPainter.end();
```

When drawing a triangle you must pass the 3 coordinates a, b, c as x, y Float parameters relative to the screen dimensions which might be ( 1024, 768 ). 
```
     ax, ay, bx, by, cx, cy 
```

When drawing an image you must also supply the u, v coordinates for each corner a, b, c of your triangle, these coordinates range from 0 to 1.
```
     au, av, bu, bv, cu, cv
```

## Triangle Options

- **drawFillTriangle**
    
    used for drawing a flat colored triangle to build simple shapes.

``` Haxe
        polyPainter.drawFillTriangle( ax, ay, bx, by, cx, cy, Color.Red );
```

- **drawGradientTriangle**
    
    used for constructing gradients.
    
``` Haxe
        polyPainter.drawFillTriangle( ax, ay, bx, by, cx, cy, Color.Red, Color.Green, Color.Blue );
```

- **drawImageTriangle**

    used for textured triangles, can be used like a mask, an optional alpha value allows easy control of opacity.

``` Haxe
        polyPainter.drawImageTriangle( ax, ay, bx, by, cx, cy, au, av, bu, bv, cu, cv
                                     , kha.Assets.images.myImage, optionAlpha );
```

- **drawImageTriagleGradient**

    useful if you want to perhaps fade or tint an image, more of an advanced feature for special occasions.
    
``` Haxe
        polyPainter.drawImageTriangle( ax, ay, bx, by, cx, cy, au, av, bu, bv, cu, cv
                                     , kha.Assets.images.myImage, colorA, colorB, colorC );
```
## Example Use
### See the *Main.hx* in the src folder.

____________________________________________________________________________________________________________________________________
## Demo

[polypainter test](https://nanjizal.github.io/PolyPainter/build/html5/index.html) ( could create more interesting demo ).