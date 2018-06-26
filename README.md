# PZFileUploader

## #特性

PZFileUploader是一个基于[策略模式](http://pany.fun/post/策略模式/)设计的文件上传组件框架，它具有 高度解耦、极易扩展、维护成本低、自定义程度高、易接入、易移植 等优点。

> PZFileUploaderDemo中仅提供了大体框架和思路，一些诸如 token请求过程、上传返回的数据解析 等业务细节需要自己实现



## #使用

#### - 基本使用方式

主要需要关注的类有两个

- PZFileUploader	

  这是上传工具的管理类，以单例形式提供，包含了外部上传调用的主接口以及token请求的url配置接口

- PZFileTypeBase     

  用于区分上传的文件类型的基类，其内部已经实现了上传的主要流程，其upload接口提供给PZFileUploader调用。

上传文件时，调用PZFileUploader中的upload接口，并传入相应文件和type实例即可

#### - 如何添加文件类型支持

当需要添加新的上传文件类型时，非常的简单，只需要新建一个type类并继承到PZFileTypeBase即可

#### - 如何自定义token请求流程/上传流程

在自己的type子类中重写`- requestToken: `方法即可自定义token请求流程，token请求所需的参数可以作为type的属性。参考 PZFileTypeVideo.m

在自己的type子类中重写`- upload:withParams: `方法即可自定义上传流程以及上传完成后的数据解析。参考 PZFileTypeCrashLog.m

#### - 文件组织建议

为了达到高度解耦以及新平台的易移植特性，建议将PZFileUploader类、PZUploadToken类、PZFileTypeBase类作为平台型中间件以方便新app的快速移植，而其它的PZFileTypeBase的子类，作为业务型中间件，以满足更加贴合业务需求的上传功能