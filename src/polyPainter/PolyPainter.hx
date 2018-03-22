package polyPainter;
import kha.Framebuffer;
import kha.arrays.Float32Array;
import kha.Canvas;
import kha.Color;
import kha.FastFloat;
import kha.Font;
import kha.graphics2.ImageScaleQuality;
import kha.Image;
import kha.graphics4.PipelineState;
import kha.graphics4.Graphics2;
import kha.graphics4.Graphics;
import kha.graphics4.BlendingOperation;
import kha.graphics4.BlendingFactor;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CullMode;
import kha.graphics4.IndexBuffer;
import kha.graphics4.MipMapFilter;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureUnit;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix3;
import kha.math.FastMatrix4;
import kha.math.FastVector2;
import kha.math.Matrix3;
import kha.math.Matrix4;
import kha.math.Vector2;
import kha.Shaders;
import kha.simd.Float32x4;
@:enum  // note careful abstract enums brake KodeGarden?
abstract ShaderMode( Int ){
    var GradientMode = 0;
    var ImageMode = 1;
}
class PolyPainter{

    var projectionMatrix: FastMatrix4;
    static var shaderPipelineImage: PipelineState = null;
    static var shaderPipelineGradient: PipelineState = null;
    static var structureImage: VertexStructure = null;
    static var structureGradient: VertexStructure = null;
    static inline var bufferSize: Int = 1500;
    static inline var vertexSizeImage: Int = 9;
    static inline var vertexSizeGradient: Int = 7;
    static var bufferIndexImage: Int;
    static var bufferIndexGradient: Int;
    static var vertexBufferImage: VertexBuffer;
    static var vertexBufferGradient: VertexBuffer;
    static var verticesImage: Float32Array;
    static var verticesGradient: Float32Array;
    static var indexBufferImage: IndexBuffer;
    static var indexBufferGradient: IndexBuffer;
    static var lastTexture: Image;
    static var vertexPosImage :Int = 0;
    static var vertexPosGradient: Int = 0;
    var shaderMode = ImageMode;
    var bilinear: Bool = false;
    var bilinearMipmaps: Bool = false;    
    var g: Graphics;
    var myPipeline: PipelineState = null;
    var projectionLocationImage: ConstantLocation;
    var textureLocation: TextureUnit;
    var projectionLocationGradient: ConstantLocation;
    var isFramebuffer: Bool;
    var width: Int;
    var height: Int;
    var writePosImage:Int = 0;
    var writePosGradient: Int = 0;
    public var pipeline(get, set): PipelineState;

    public var sourceBlend: BlendingFactor = BlendingFactor.Undefined;
    public var destinationBlend: BlendingFactor = BlendingFactor.Undefined;

    public function new(){
        bufferIndexGradient = 0;
        bufferIndexImage = 0;
        initShaders();
        initBuffers();
        projectionLocationImage = shaderPipelineImage.getConstantLocation("projectionMatrix");
        projectionLocationGradient = shaderPipelineGradient.getConstantLocation("projectionMatrix");
        textureLocation = shaderPipelineImage.getTextureUnit("tex");
    }

    public function setProjection( projectionMatrix: FastMatrix4 ): Void {
        this.projectionMatrix = projectionMatrix;
    }
    
    private static function upperPowerOfTwo( v: Int ): Int {
        v--;
        v |= v >>> 1;
        v |= v >>> 2;
        v |= v >>> 4;
        v |= v >>> 8;
        v |= v >>> 16;
        v++;
        return v;
    }

    private static function initShaders(): Void {
        initImageShader();
        initGradientShader();
    }
    private static function initImageShader():Void {
        if( structureImage == null ){
            structureImage = Graphics2.createImageVertexStructure();
        }
        if( shaderPipelineImage == null ){
            shaderPipelineImage = Graphics2.createImagePipeline( structureImage );
            shaderPipelineImage.compile();
        }
    }
    private static function initGradientShader():Void {
        if( structureGradient == null ){
            structureGradient = Graphics2.createColoredVertexStructure();
        }
        if( shaderPipelineGradient == null ) {
            shaderPipelineGradient = Graphics2.createColoredPipeline( structureGradient );
            shaderPipelineGradient.compile();
        }
    }

    private function get_pipeline(): PipelineState {
        return myPipeline;
    }
    
    private function set_pipeline( pipe: PipelineState ): PipelineState {
        if(pipe != myPipeline)
        flush();

        if( pipe == null ) {
            projectionLocationImage = shaderPipelineImage.getConstantLocation( "projectionMatrix" );
            textureLocation = shaderPipelineImage.getTextureUnit( "tex" );
        } else if( pipe == shaderPipelineGradient ){
            projectionLocationImage = pipe.getConstantLocation( "projectionMatrix" );
        } else {
            projectionLocationImage = pipe.getConstantLocation( "projectionMatrix" );
            textureLocation = pipe.getTextureUnit( "tex" );
        }
        return myPipeline = pipe;
    }

    private function initBuffers(): Void {
        initBuffersImage();
        initBuffersGradient();
    }
    private function initBuffersImage():Void {
        if (vertexBufferImage == null) {
            vertexBufferImage = new VertexBuffer( bufferSize, structureImage, Usage.DynamicUsage );
            verticesImage = vertexBufferImage.lock();
            
            indexBufferImage = new IndexBuffer( bufferSize*3, Usage.StaticUsage );
            var indicesImage = indexBufferImage.lock();
            for( i in 0...bufferSize*3 ) {
                indicesImage[ i * 3 + 0 ] = i *3 + 0;
                indicesImage[ i * 3 + 1 ] = i *3 + 1;
                indicesImage[ i * 3 + 2 ] = i *3 + 2;
            }
            indexBufferImage.unlock();
        }
    }
    private function initBuffersGradient(): Void {
        if (vertexBufferGradient == null) {
            vertexBufferGradient = new VertexBuffer( bufferSize, structureGradient, Usage.DynamicUsage );
            verticesGradient = vertexBufferGradient.lock();
            
            indexBufferGradient = new IndexBuffer( bufferSize*3, Usage.StaticUsage );
            var indicesGradient = indexBufferGradient.lock();
            for( i in 0...bufferSize*3 ) {
                indicesGradient[ i * 3 + 0 ] = i *3 + 0;
                indicesGradient[ i * 3 + 1 ] = i *3 + 1;
                indicesGradient[ i * 3 + 2 ] = i *3 + 2;
            }
            indexBufferGradient.unlock();
        }
    }

    public function drawGradientTriangle( ax: Float, ay: Float, bx: Float, by: Float, cx: Float, cy: Float 
                                    ,     color0: Color, color1: Color, color2: Color ){
        if( shaderMode == ImageMode ) flush();
        var writePos = writePosGradient;
        verticesGradient.set( writePos +  0, ax );
        verticesGradient.set( writePos +  1, ay );
        verticesGradient.set( writePos +  2, -5.0 );
        verticesGradient.set( writePos +  3, color0.R );
        verticesGradient.set( writePos +  4, color0.G );
        verticesGradient.set( writePos +  5, color0.B );
        verticesGradient.set( writePos +  6, color0.A );
        writePos +=7;
        verticesGradient.set( writePos +  0, bx );
        verticesGradient.set( writePos +  1, by );
        verticesGradient.set( writePos +  2, -5.0 );
        verticesGradient.set( writePos +  3, color1.R );
        verticesGradient.set( writePos +  4, color1.G );
        verticesGradient.set( writePos +  5, color1.B );
        verticesGradient.set( writePos +  6, color1.A );
        writePos +=7;
        verticesGradient.set( writePos +  0, cx );
        verticesGradient.set( writePos +  1, cy );
        verticesGradient.set( writePos +  2, -5.0 );
        verticesGradient.set( writePos +  3, color2.R );
        verticesGradient.set( writePos +  4, color2.G );
        verticesGradient.set( writePos +  5, color2.B );
        verticesGradient.set( writePos +  6, color2.A );
        writePos +=7;
        writePosGradient = writePos;
        bufferIndexGradient++;
    }
    public function drawImageTriangle( ax: Float, ay: Float, bx: Float, by: Float, cx: Float, cy: Float 
                                    ,  au: Float, av: Float, bu: Float, bv: Float, cu: Float, cv: Float
                                    , img: Image, ?alpha: Float = 1.){
        var color = Color.White;
        if( alpha != 1. ) color.A = alpha;
        if( lastTexture != img || shaderMode == GradientMode ) flush();
        lastTexture = img; 
        var writePos = writePosImage;
        verticesImage.set( writePos +  0, ax );
        verticesImage.set( writePos +  1, ay );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, au );
        verticesImage.set( writePos +  4, av );
        verticesImage.set( writePos +  5, color.R );
        verticesImage.set( writePos +  6, color.G );
        verticesImage.set( writePos +  7, color.B );
        verticesImage.set( writePos +  8, color.A );
        writePos+=9;
        verticesImage.set( writePos +  0, bx );
        verticesImage.set( writePos +  1, by );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, bu );
        verticesImage.set( writePos +  4, bv );
        verticesImage.set( writePos +  5, color.R );
        verticesImage.set( writePos +  6, color.G );
        verticesImage.set( writePos +  7, color.B );
        verticesImage.set( writePos +  8, color.A );
        writePos+=9;
        verticesImage.set( writePos +  0, cx );
        verticesImage.set( writePos +  1, cy );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, cu );
        verticesImage.set( writePos +  4, cv );
        verticesImage.set( writePos +  5, color.R );
        verticesImage.set( writePos +  6, color.G );
        verticesImage.set( writePos +  7, color.B );
        verticesImage.set( writePos +  8, color.A );
        writePos+=9;
        writePosImage = writePos;
        bufferIndexImage++;
    }
    // this is mainly for if you want to alpha out part of an image
    // still uses image shader.
    public function drawImageTriangleGradient( ax: Float, ay: Float, bx: Float, by: Float, cx: Float, cy: Float 
                                    ,  au: Float, av: Float, bu: Float, bv: Float, cu: Float, cv: Float
                                    , img: Image, color0: Color, color1: Color, color2: Color ){
        if( lastTexture != img || shaderMode == GradientMode ) flush();
        lastTexture = img; 
        var writePos = writePosImage;
        verticesImage.set( writePos +  0, ax );
        verticesImage.set( writePos +  1, ay );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, au );
        verticesImage.set( writePos +  4, av );
        verticesImage.set( writePos +  5, color0.R );
        verticesImage.set( writePos +  6, color0.G );
        verticesImage.set( writePos +  7, color0.B );
        verticesImage.set( writePos +  8, color0.A );
        writePos+=9;
        verticesImage.set( writePos +  0, bx );
        verticesImage.set( writePos +  1, by );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, bu );
        verticesImage.set( writePos +  4, bv );
        verticesImage.set( writePos +  5, color1.R );
        verticesImage.set( writePos +  6, color1.G );
        verticesImage.set( writePos +  7, color1.B );
        verticesImage.set( writePos +  8, color1.A );
        writePos+=9;
        verticesImage.set( writePos +  0, cx );
        verticesImage.set( writePos +  1, cy );
        verticesImage.set( writePos +  2, -5.0 );
        verticesImage.set( writePos +  3, cu );
        verticesImage.set( writePos +  4, cv );
        verticesImage.set( writePos +  5, color2.R );
        verticesImage.set( writePos +  6, color2.G );
        verticesImage.set( writePos +  7, color2.B );
        verticesImage.set( writePos +  8, color2.A );
        writePos+=9;
        writePosImage = writePos;
        bufferIndexImage++;
    }

    public var framebuffer( null, set ): Framebuffer;
    function set_framebuffer( f: Framebuffer ): Framebuffer {
        g = f.g4;
        isFramebuffer = true;
        width = f.width;
        height = f.height;
        shaderMode = ImageMode;
        return f;
    }

    public var canvas( null, set ): Canvas;
    function set_canvas( c: Canvas ): Canvas {
        g = c.g4;
        isFramebuffer = false;
        width = c.width;
        height = c.height;
        shaderMode = GradientMode;
        return c;
    }

    private function getProjectionMatrix(): Void {
        if ( isFramebuffer ) {
            projectionMatrix = FastMatrix4.orthogonalProjection( 0, width, height, 0, 0.1, 1000 );
        } else {
            if( !Image.nonPow2Supported ) {
                width = upperPowerOfTwo( width );
                height = upperPowerOfTwo( height );
            }
            if( g.renderTargetsInvertedY() ) {
                projectionMatrix = FastMatrix4.orthogonalProjection( 0, width, 0, height, 0.1, 1000 );
            } else {
                projectionMatrix = FastMatrix4.orthogonalProjection( 0, width, height, 0, 0.1, 1000 );
            }
        }
    }
    
    private function setPipeline( pipeline: PipelineState ): Void {
        this.pipeline = pipeline;
        if (pipeline != null) g.setPipeline( pipeline );
    }
    
    private function drawBuffer():Void {
        drawBufferImage();
        drawBufferGradient();
    }

    private function drawBufferGradient():Void{
        vertexBufferGradient.unlock();
        g.setVertexBuffer( vertexBufferGradient );
        g.setIndexBuffer( indexBufferGradient );
        g.setPipeline( shaderPipelineGradient );//pipeline == null ? shaderPipelineGradient : pipeline);
        g.setMatrix( projectionLocationGradient, projectionMatrix );
        g.drawIndexedVertices( 0, bufferIndexGradient*3 );
        bufferIndexGradient = 0;
        writePosGradient = 0;
        verticesGradient = vertexBufferGradient.lock();
    }

    private function drawBufferImage(): Void {
        vertexBufferImage.unlock();
        g.setVertexBuffer(vertexBufferImage);
        g.setIndexBuffer(indexBufferImage);
        g.setPipeline( shaderPipelineImage );//pipeline == null ? shaderPipelineImage : pipeline);
        g.setTexture( textureLocation, lastTexture );
        g.setTextureParameters( textureLocation, TextureAddressing.Clamp, TextureAddressing.Clamp, bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter, bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter, bilinearMipmaps ? MipMapFilter.LinearMipFilter : MipMapFilter.NoMipFilter );
        g.setMatrix( projectionLocationImage, projectionMatrix );

        g.drawIndexedVertices(0, bufferIndexImage*3);

        g.setTexture( textureLocation, null );
        bufferIndexImage = 0;
        writePosImage = 0;
        verticesImage = vertexBufferImage.lock();
    }

    public function begin(clear: Bool = true, clearColor: Color = null): Void {
        if( g == null ) return;
        g.begin();
        if ( clear ) g.clear( clearColor );
        getProjectionMatrix();
    }

    public function clear( color: Color = null ): Void {
        if( g == null ) return;
        drawBuffer();
        g.clear( color == null ? Color.Black : color );
    }

    public function end(){
        if( g == null ) return;
        flush();
        g.end();
    }

    function flush(){
        if( bufferIndexImage > 0 ) drawBufferImage();
        if( bufferIndexGradient > 0 ) drawBufferGradient();
    }

}