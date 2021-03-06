﻿<script language="jscript" runat="server">
/*
** 创建一个新的Controller对象；
** 语法：newController = IController.create([__construct[,__destruct]]);
** __construct：构造函数；
** __destruct：析构函数；
*/
TestController = IController.create(
	function(){
		this.Name="我来自另外的Controller！";
	}
);

TestController.extend("U", function(){
	C("@.MO_REWRITE_MODE","URL");
	F.echo(Mo.U("?id=2"),true);
	F.echo(Mo.U("Home/Save"),true);
	F.echo(Mo.U("Home/Save?id=2"),true);
	F.echo(Mo.U("Home/Save!"),true);
	F.echo(Mo.U("Admin/Home/Index?id=2&name={$name}!"),true);
	F.echo(Mo.U("Admin/Home/Index?id=2&name={$name}@dev.mo.cn"),true);
});

TestController.extend("Test2", function(){
	F.require("net/http/winhttp");
	F.dump(F.exports.net.http.winhttp.postJSON("http://dwz.cn/create.php",{url:"http://www.baidu.com/"}));
});

TestController.extend("Res", function(){
	F.echo("输出：<br />");
	F.echo(F.server("QUERY_STRING"),true);
	F.echo(F.get("c"),true);
	F.echo(F.get("d"));
});
/*
** 为新Controller对象扩展一个新方法，对应相应的动作；
** 语法：newController.extend(funcName,callback);
** funcName：方法名；
** callback：要执行的函数；
*/
TestController.extend("Index", function(name){
	return this.Name + " - " + name;
});

TestController.extend("Show2", function(mode){
	var zip = F.activex("Zip.Manager");
	zip.Explode(F.mappath("/Mo.zip"),F.mappath("/Mo2/"));
	F.echo("<pre>"+zip.Exception.Message+"</pre>",true);
});

TestController.extend("Show", function(mode){
	var zip = F.activex("Zip.Manager");
	zip.OpenRead(F.mappath("/Mo.zip"),"sssss");
	var entry=null;
	while((entry = zip.NextEntry) != null){
		F.echo(entry.Name+","+entry.IsDirectory,true);
	}
	F.echo("<pre>"+zip.Exception.Message+"</pre>",true);
});

TestController.extend("ShowZip", function(mode){
	var zip = F.activex("Zip.Manager");
	zip.OneDirectory(F.mappath("/Mo/"),F.mappath("/Mo.zip"));
	F.echo("<pre>"+zip.Exception.Message+"</pre>",true);
});

TestController.extend("Attrs", function(){
	var path = __DIR__ + "\\20140721.png", attr = -1;
	F.echo("文件路径：" + path, true);
	
	F.echo("<br />设置属性：系统、只读、隐藏", true);
	attr = IO.attr(path,IO.attrs.System | IO.attrs.ReadOnly | IO.attrs.Hidden);
	F.echo("操作结果：" + IO.attr.toString(attr), true);
	
	F.echo("<br />添加属性：存档", true);
	attr = IO.attr.add(path,IO.attrs.Archive);
	F.echo("操作结果：" + IO.attr.toString(attr), true);
	
	F.echo("<br />移除属性：系统", true);
	attr = IO.attr.remove(path,IO.attrs.System)
	F.echo("操作结果：" + IO.attr.toString(attr), true);
	
	F.echo("<br />移除属性：隐藏", true);
	attr = IO.attr.remove(path,IO.attrs.Hidden);
	F.echo("操作结果：" + IO.attr.toString(attr), true);
});
TestController.extend("Session", function(){
	var Session = F.require("session");
	Session("name","艾恩123456789sdfsdfsdf");
	Session.setTimeout(800);
	F.echo("<a href=\"?m=Test&a=ShowSession&sessionid=" + Session.id + "\" target=\"_blank\">查看</a>");
});

TestController.extend("ShowSession", function(){
	var Session = F.require("session");
	F.echo(Session("name"),true);
	F.echo(Session.timeout,true);
	F.echo(Session.id,true);
});
/*
** 发送http-request请求到本控制器的ShowServer方法；
*/
TestController.extend("HttpRequest", function(){
	F.require("net/http/request");
	var text = Exports.net.http.request.create(
		"http://" + F.server("HTTP_HOST") + Mo.Config.Global.MO_ROOT + "?m=Test&a=ShowServer",
		{
			method : "POST",
			headers : [
				"user-agent:MoAspEnginer1.0"
			],
			data : "data=sadasdsad",
			charset : "gbk"
		}
	).send().gettext("utf-8");
	F.echo("<pre>");
	F.echo(F.encodeHtml(text));
	F.echo("</pre>");
});
TestController.extend("ShowServer", function(){
	F.dump(F.get());
	F.echo("\r\n");
	F.dump(F.post());
	F.echo("\r\n");
	F.dump(F.server());
});


/*
** 发送http-upload请求到本控制器的UploadFile方法；
*/
TestController.extend("HttpUpload", function(){
	F.require("net/http/upload");
	/*Exports.net.http.upload.create(url[,opt])*/
	var upload = Exports.net.http.upload.create(
		"http://" + F.server("HTTP_HOST") + Mo.Config.Global.MO_ROOT + "?m=Test&a=UploadFile",
		/*下面通过create方法直接添加表单数据*/
		{
			forms :{
				"form1" : "测试"
			},
			files : 
			{
				"file1" : __DIR__ + "\\20140721.png",
				"file2" : 
				{
					path : __DIR__ + "\\20140721.png",
					contentType : "image/png"
				}
			}
		}
	);
	/*也可以通过下面的接口添加表单数据*/
	upload.appendForm("select1","select测试1");
	upload.appendFile("file1",__DIR__ + "\\20140721.png","image/png"); /*支持同表单名的多文件。*/
	var text = upload.send().gettext("utf-8")
	F.echo("<pre>");
	F.echo(F.encodeHtml(text));
	F.echo("</pre>");
});
TestController.extend("UploadFile", function(){
	F.require("net/upload");
	F.exports.net.upload({
		AllowFileTypes : "*.jpg;*.png;*.gif;*.bmp",
		AllowMaxSize : "1Mb",
		Charset : "utf-8",
		SavePath : __DIR__ + "\\upload",
		RaiseServerError : false,
		OnError:function(e,cfg){
			F.echo("exception : "+ e, true);
		},
		OnSucceed:function(cfg){
			F.echo("filecount : " + this.files.length, true);
			F.echo("form1 : "+ F.post("form1"), true);
			F.echo("select1 : " + F.post("select1"), true);
			this.save("file1", {
				OnError : function(e){
					F.echo("file1 : " + e,true);
				},
				OnSucceed : function(count,files){
					/*支持同表单名的多文件，即：支持HTML5上传。*/
					for(var i=0;i<files.length;i++)
					{
						F.echo(files[i].FormName + " : 文件'" + files[i].LocalName + "'上传成功，保存位置'" + files[i].Path + files[i].FileName + "',文件大小" + files[i].Size + "字节",true);
					}
				}
			});
		}
	});
});


TestController.extend("Test", function(){
	/*todo*/
	var getfunction=function(fn){
		var s = fn.toString();
		return s.replace(/^function(\s(.+?))?\((.*?)\)([\s\S]+)$/,"($3)");
	};
	var parser = function(src,name){
		F.echo("<pre>");
		var members={};
		if(typeof src == "object"){
			var $F = F.object.sort(src);
			for(var i in $F){
				if(!$F.hasOwnProperty(i))continue;
				if(typeof $F[i] == "object"){
					for(var j in $F[i]){
						if(!$F[i].hasOwnProperty(j))continue;
						if(typeof $F[i][j] == "function"){
							members[name + "." + i + "." + j] = name + "." + i + "." + j + getfunction($F[i][j]) +"[静态方法]";
						}else{
							members[name + "." + i + "." + j] = name + "." + i + "." + j +"[静态属性]";
						}
					}
				}else if(typeof $F[i] == "function"){
					members[name + "." + i] = name + "." + i + getfunction($F[i]);
					for(var j in $F[i]){
						if(!$F[i].hasOwnProperty(j))continue;
						if(typeof $F[i][j] == "function"){
							members[name + "." + i + "." + j] = name + "." + i + "." + j + getfunction($F[i][j]) +"[静态方法]";
						}else{
							members[name + "." + i + "." + j] = name + "." + i + "." + j +"[静态属性]";
						}
					}
					for(var j in $F[i].prototype){
						if(!$F[i].prototype.hasOwnProperty(j))continue;
						if(typeof $F[i].prototype[j] == "function"){
							members[name + "." + i + "." + j] = name + "." + i + "." + j + getfunction($F[i].prototype[j]);
						}else{
							members[name + "." + i + "." + j] = name + "." + i + "." + j;
						}
					}
				}else{
					members[name + "." + i] = name + "." + i;
				}
			}
		}else if(typeof src=="function"){
			members[name] = name + getfunction(src);
			for(var j in src){
				if(!src.hasOwnProperty(j))continue;
				if(typeof src[j] == "function"){
					members[name + "." + j] = name + "." + j + getfunction(src[j]) +"[静态方法]";
				}else{
					members[name + "." + j] = name + "." + j + "[静态属性]";
				}
			}
			for(var j in src.prototype){
				if(!src.prototype.hasOwnProperty(j))continue;
				if(typeof src.prototype[j] == "function"){
					members[name + "." + j] = name + "." + j + getfunction(src.prototype[j]);
				}else{
					members[name + "." + j] = name + "." + j;
				}
			}
		}
		members = F.object.sort(members);
		for(var i in members){
			if(!members.hasOwnProperty(i))continue;
			F.echo(members[i],F.TEXT.NL);
		}
		F.echo("</pre>");
	};
	parser(F,"F");
	parser(Mo,"Mo");
	parser(Model__,"Model__");
	parser(__Model__,"Model__");
	parser(DataTable,"DataTable");
	parser(DataTableRow,"DataTableRow");
	parser(IClass,"IClass");
	parser(IController,"IController");
	parser(ExceptionManager,"ExceptionManager");
	parser(Exception,"Exception");
	parser(ModelCMDManager,"ModelCMDManager");
	parser(IO,"IO");
	parser(F.require("encoding"),"Encoding");
});
TestController.extend("empty", function(name){
	F.echo("调用不到" + name + "方法，就跑到empty方法了！",true);
});
</script>