//
//  NoddyThread.m
//  NodeTest
//
//  Created by Jean-Nicolas Jolivet on 12-07-01.
//  Copyright (c) 2012 Jean-Nicolas Jolivet. All rights reserved.
//

#import "NoddyThread.h"
#import <node.h>
//#import <node_events.h>
//#import <stdlib.h>

using namespace v8;

static ev_prepare gPrepareNodeWatcher;

void noddy_init(v8::Handle<v8::Object> target) {
}

static void NoddyPrepareNode(EV_P_ ev_prepare *watcher, int revents) {
    HandleScope scope;
    Persistent<Object> gKodNodeModule;
    // Create _choc module
    Local<FunctionTemplate> kod_template = FunctionTemplate::New();
    node::EventEmitter::Initialize(kod_template);
    gKodNodeModule = Persistent<Object>::New(kod_template->GetFunction()->NewInstance());
    noddy_init(gKodNodeModule);
    Local<Object> global = v8::Context::GetCurrent()->Global();
    global->Set(String::New("_choc"), gKodNodeModule);
    
    ev_prepare_stop(ev_default_loop(0), &gPrepareNodeWatcher);
    
}
@implementation NoddyThread

- (void)main
{
    // args
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    const char *argv[] = {NULL,"","",NULL};
    argv[0] = [[[NSBundle mainBundle] bundlePath] fileSystemRepresentation];
    int argc = 2;
    argv[argc-1] = [[[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"chocolat.js"] fileSystemRepresentation];
    
    // NODE_PATH
    NSString *nodelibPath = [[NSBundle mainBundle] sharedSupportPath];
    nodelibPath = [nodelibPath stringByAppendingPathComponent:@"nodelib"];
    const char *NODE_PATH_pch = getenv("NODE_PATH");
    NSString *NODE_PATH;
    if (NODE_PATH_pch) {
        NODE_PATH = [NSString stringWithFormat:@"%@:%s",nodelibPath, NODE_PATH_pch];
    } else {
        NODE_PATH = nodelibPath;
    }
    setenv("NODE_PATH", [NODE_PATH UTF8String], 1);
    
    // Make sure HOME is correct and set
    setenv("HOME", [NSHomeDirectory() UTF8String], 1);
    
    // register our initializer
    ev_prepare_init(&gPrepareNodeWatcher, NoddyPrepareNode);
    // set max priority so _KPrepareNode gets called before main.js is executed
    ev_set_priority(&gPrepareNodeWatcher, EV_MAXPRI);
    
    // start and win?
    int exitStatus = node::Start(argc, (char**)argv);
    
    [pool drain];
}

@end
