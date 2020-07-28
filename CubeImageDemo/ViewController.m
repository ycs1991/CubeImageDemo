//
//  ViewController.m
//  CubeImageDemo
//
//  Created by 鲸鱼集团技术部 on 2020/7/28.
//  Copyright © 2020 com.sanqi.net. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionGoord; //顶点坐标
    GLKVector2 textureCoord; //纹理坐标
    GLKVector3 normal;  //法线
} CSVertex;

//顶点数量
static NSInteger const kCoordCount = 36; //正方体有6个面，每个面有2个三角形，每个三角形有3个顶点

@interface ViewController ()<GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) CSVertex *vertexes;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, assign) GLuint vertexBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];

    //1. OpenGL ES 相关的初始化
    [self commonInit];

    //2. 添加定时器
    [self addCADisplayLink];
}

- (void)commonInit {
    //1.创建content
    EAGLContext *content = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    //设置当前content
    [EAGLContext setCurrentContext:content];

    //2. 创建GLKView
    self.glkView = [[GLKView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width) context:content];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;

    //3.使用深度缓存
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //默认是（0，1），这里用于翻转Z轴，使正方形朝屏幕外面
    glDepthRangef(1, 0);

    //4.将GLKView添加到view上
    [self.view addSubview:self.glkView];

    //5.获取纹理图片
    NSString *imagePath = [[NSBundle mainBundle]pathForResource:@"timg" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];

    //6.设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:NULL];

    //7.使用baseEffect
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    //开启光照效果
    self.baseEffect.light0.enabled = YES;
    //漫反射颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    //光源位置
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);

    /*
    解释一下:
    这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点
    以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
    */

    //8.开辟顶点数据空间（数据结构SenceVertex大小 * 顶点个数kCoordCount）
    self.vertexes = malloc(sizeof(CSVertex) * kCoordCount);

    //前面
    // 前面
    self.vertexes[0] = (CSVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
    self.vertexes[1] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexes[2] = (CSVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexes[3] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexes[4] = (CSVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexes[5] = (CSVertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};

    // 上面
    self.vertexes[6] = (CSVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
    self.vertexes[7] = (CSVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexes[8] = (CSVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexes[9] = (CSVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexes[10] = (CSVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexes[11] = (CSVertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};

    // 下面
    self.vertexes[12] = (CSVertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
    self.vertexes[13] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexes[14] = (CSVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexes[15] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexes[16] = (CSVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexes[17] = (CSVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};

    // 左面
    self.vertexes[18] = (CSVertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
    self.vertexes[19] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexes[20] = (CSVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexes[21] = (CSVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexes[22] = (CSVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexes[23] = (CSVertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};

    // 右面
    self.vertexes[24] = (CSVertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
    self.vertexes[25] = (CSVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexes[26] = (CSVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexes[27] = (CSVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexes[28] = (CSVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexes[29] = (CSVertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};

    // 后面
    self.vertexes[30] = (CSVertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
    self.vertexes[31] = (CSVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexes[32] = (CSVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexes[33] = (CSVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexes[34] = (CSVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexes[35] = (CSVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};

    //开辟顶点缓存区
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(CSVertex) * kCoordCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertexes, GL_STATIC_DRAW);

    //顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(CSVertex), NULL + offsetof(CSVertex, positionGoord));

    //纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(CSVertex), NULL + offsetof(CSVertex, textureCoord));

    //法线数据
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(CSVertex), NULL + offsetof(CSVertex, normal));
}

- (void)addCADisplayLink {
    //定时器提供一个周期性调用
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)update {
    //1.计算旋转度数
    self.angle = (self.angle + 5) % 360;
    //2. 修改baseEffect
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, 0.7);
    //3.重新渲染
    [self.glkView display];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //1.开启深度测试
    glEnable(GL_DEPTH_TEST);
    //2.清除颜色缓存区和深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //3.准备绘制
    [self.baseEffect prepareToDraw];
    //4.绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertexes) {
        free(_vertexes);
        _vertexes = nil;
    }
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }

    [self.displayLink invalidate];
}

@end
