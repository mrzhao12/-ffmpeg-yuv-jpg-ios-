//
//  ViewController.m
//  没用脚本的编译ffmpeg-ios版
//
//  Created by sjhz on 2017/5/9.
//  Copyright © 2017年 sjhz. All rights reserved.
//

#import "ViewController.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
     printf("eeee%s\n", avcodec_configuration());
    // Do any additional setup after loading the view, typically from a nib.
    
    
    AVFormatContext* pFormatCtx;
    AVOutputFormat* fmt;
    AVStream* video_st;
    AVCodecContext* pCodecCtx;
    AVCodec* pCodec;
    
    uint8_t* picture_buf;
    AVFrame* picture;
    AVPacket pkt;
    int y_size;
    int got_picture=0;
    int size;
    
    int ret=0;
    
    FILE *in_file = NULL;                            //YUV source/Users/zhaotong/Desktop/test.yuv   cuc_view_480x272.yuv
    int in_w=480,in_h=272;                           //YUV's width and height/Users/zhaotong/Desktop/壹件事-周报
    const char* out_file = "/Users/zhaotong/Desktop/壹件事-周报/cucee_view_encode.jpg";    //Output file
    
//    in_file = fopen("cuc_view_480x272.yuv", "rb");/Users/zhaotong/Desktop/cuc_view_480x272.yuv
    in_file = fopen("/Users/zhaotong/Desktop/cuc_view_480x272.yuv", "rb");

    av_register_all();
    
    //Method 1
    pFormatCtx = avformat_alloc_context();
    //Guess format
    fmt = av_guess_format("mjpeg", NULL, NULL);
    pFormatCtx->oformat = fmt;
    //Output URL
    if (avio_open(&pFormatCtx->pb,out_file, AVIO_FLAG_READ_WRITE) < 0){
        printf("----Couldn't open output file.");
//        return -1;
        return;
    }
    
    //Method 2. More simple
    //avformat_alloc_output_context2(&pFormatCtx, NULL, NULL, out_file);
    //fmt = pFormatCtx->oformat;
    
    video_st = avformat_new_stream(pFormatCtx, 0);
    if (video_st==NULL){
//        return -1;
            return;
    }
    pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    //    pCodecCtx->pix_fmt = PIX_FMT_YUVJ420P;
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    
    pCodecCtx->width = in_w;
    pCodecCtx->height = in_h;
    
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;
    //Output some information
    av_dump_format(pFormatCtx, 0, out_file, 1);
    
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec){
        printf("Codec not found.");
//        return -1;
        return;
        
    }
    if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0){
        printf("Could not open codec.");
        return;
    }
    picture = av_frame_alloc();
    size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    picture_buf = (uint8_t *)av_malloc(size);
    if (!picture_buf)
    {
//        return -1;
            return;
    }
    avpicture_fill((AVPicture *)picture, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    
    //Write Header
    avformat_write_header(pFormatCtx,NULL);
    
    y_size = pCodecCtx->width * pCodecCtx->height;
    av_new_packet(&pkt,y_size*3);
    //Read YUV
    if (fread(picture_buf, 1, y_size*3/2, in_file) <=0)
    {
        printf("Could not read input file.");
//        return -1;
            return;
    }
    picture->data[0] = picture_buf;  // ¡¡∂»Y
    picture->data[1] = picture_buf+ y_size;  // U
    picture->data[2] = picture_buf+ y_size*5/4; // V
    
    //Encode
    ret = avcodec_encode_video2(pCodecCtx, &pkt,picture, &got_picture);
    if(ret < 0){
        printf("Encode Error.\n");
//        return -1;
            return;
    }
    if (got_picture==1){
        pkt.stream_index = video_st->index;
        ret = av_write_frame(pFormatCtx, &pkt);
    }
    
    av_free_packet(&pkt);
    //Write Trailer
    av_write_trailer(pFormatCtx);
    
    printf("Encode Successful.\n");
    
    if (video_st){
        avcodec_close(video_st->codec);
        av_free(picture);
        av_free(picture_buf);
    }
    avio_close(pFormatCtx->pb);
    avformat_free_context(pFormatCtx);
    
    fclose(in_file);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
