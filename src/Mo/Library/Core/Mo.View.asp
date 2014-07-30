﻿<script language="jscript" runat="server">
var exports=["MoAspEnginerView"];
var G = Mo.Config.Global;
function MoAspEnginerView(content){
	this.mvarDicts={};
	this.Content="";
	this.loops = ";";
	this.setContent(content).parse();
}
MoAspEnginerView.prototype.setContent=function(content){
	content = F.string.replace(content,/<switch(.+?)>(\s*)<case/igm,"<switch$1><case");
	content= F.string.replace(content,/\r\n/igm,"--movbcrlf--");
	content= F.string.replace(content,/\r/igm,"--movbcrlf--");
	content= F.string.replace(content,/\n/igm,"--movbcrlf--");
	content= F.string.replace(content,/(--movbcrlf--){1,}/igm,"--movbcrlf--");
	content= F.string.replace(content,/--movbcrlf--/igm,"--movbcrlf--\r\n");
	this.Content = content;
	return this;
}
MoAspEnginerView.prototype.parse=function(){
	this.parsePreCombine();
	if(G.MO_TAG_LIB!=""){
		var libs=G.MO_TAG_LIB.split(","),lib,closetag,tagcontent;
		for(var i=0;i<libs.length;i++){
			lib = libs[i];
			closetag = true;
			tagcontent = "";
			Mo.Use("TagLib:Tag." + lib);
			var taglib = F.initialize("MoTag" + lib),match,
			regexp = new RegExp("\\<" + lib + "\\b([\\s\\S]*?)\\>([\\s\\S]*?)\\<\\/" + lib + "\\>","igm"),
			matches = F.string.matches(this.Content,regexp);
			if(matches && matches>0){
				closetag = false;
			}else{
				regexp = new RegExp("\\<" + lib + "\\b([\\s\\S]*?)\\/\\>","igm");
				matches =F.string.matches(this.Content,regexp);
			}
			if(!matches)continue;
			while(matches.length>0){
				match = matches.pop();
				if(!closetag) tagcontent = match[2];
				while(this.Content.indexOf(match[0])>=0){
					this.Content = this.Content.replace(match[0],taglib.Index(F.readAttrs(match[1]),tagcontent))
				}
			}
		}
	}
	this.parseSource();
	this.getLoops(["loop","foreach"]);
	this.parsePage();
	this.parseVari(["#","@"]);
	this.parseLoop();
	this.parseForeach();
	this.parseEmpty();
	this.parseSwitch();
	this.parseCompare(["lt","gt","nlt","ngt","eq","neq"]);
	this.parseExpression();
	this.parseExpressionElse();
	this.Content = F.string.replace(this.Content,/<\/else>/igm,"<?MoAsp }else{ MoAsp?>");
	this.Content = F.string.replace(this.Content,/<else \/>/igm,"<?MoAsp }else{ MoAsp?>");
	this.Content = F.string.replace(this.Content,/<break \/>/igm,"<?MoAsp break; MoAsp?>");
	this.Content = F.string.replace(this.Content,/<\/switch>/igm,"<?MoAsp } MoAsp?>");
	this.Content = F.string.replace(this.Content,/<default \/>/igm,"<?MoAsp default : MoAsp?>");
	this.Content = F.string.replace(this.Content,/<\/(n)?(eq|empty|lt|gt|expression)>/igm,"<?MoAsp } MoAsp?>");
	this.parseVari("");
	this.parseAssignName();
	this.parseMoAsAsp();
	this.doSomethingToAsp();
}

//****************************************************
//@DESCRIPTION:	PreCombine the template with global values,such as "{$$MO_CORE}"
//****************************************************
MoAspEnginerView.prototype.parsePreCombine=function(){
	var match,matches,value;
	var regexp=/\{\$\$(\w+)\}/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		eval("value=Mo.Config.Global[\"" + match[1]+"\"]");
		this.Content = F.replace(this.Content,match[0],value)
	}
}

//****************************************************
//@DESCRIPTION:	do something to the code that was combined to make the code pretty,such as remove blank lines
//****************************************************
MoAspEnginerView.prototype.doSomethingToAsp=function(){
	if(G.MO_DIRECT_OUTPUT){
		this.Content = "if(typeof Mo==\"undefined\"){Response.Write(\"invalid call.\");Response.End();}\r\n" + this.Content.replace(/__Mo__\.Echo\(/igm,"T = T `&&` (")
	}else{
		this.Content = "if(typeof Mo==\"undefined\"){Response.Write(\"invalid call.\");Response.End();}\r\nfunction Temp___(){\r\nvar WriteStreamText=function(st,txt){if(txt==null)txt=\"\";txt=txt.toString();st.WriteText(txt);};\r\n"
		+"var TplStream = F.activex.stream();\r\n"
		+"TplStream.Mode=3;\r\n"
		+"TplStream.Type=2;\r\n"
		+"TplStream.Charset=Mo.Config.Global.MO_CHARSET;\r\n"
		+"TplStream.Open();\r\n"
		+ this.Content.replace(/__Mo__\.Echo\(/igm,"T = T `&&` (")
		+ "\r\n"
		+"TplStream.Position=0;\r\n"
		+"var Temp____ = TplStream.ReadText();\r\n"
		+"TplStream.Close();\r\ndelete WriteStreamText;\r\nreturn Temp____;\r\n"
		+"}"
	}
	this.Content = this.Content.replace(/--movbcrlf--/igm,"\\r\\n")
	if(G.MO_PREETY_HTML){
		//this.Content = this.Content.replace(/(\s*)\" `&&` vbcrlf `&&` \"(\s*)/igm,"")
		//this.Content = this.Content.replace(/\bT \= T `&&` \"(\s+)/igm,"T = T `&&` \"")
	}
	if(G.MO_DIRECT_OUTPUT){
		this.Content = this.Content.replace(/T \= T `&&` \(/igm,"Response.Write(")
		this.Content = this.Content.replace(/`&&`/igm,"\r\nResponse.Write(")
	}else{
		this.Content = this.Content.replace(/T \= T `&&` \(/igm,"WriteStreamText(TplStream,")
	}
	this.Content = this.Content.replace(/WriteStreamText\(TplStream\,\"\\r\\n\"\);\n/igm,"");
	this.Content = this.Content.replace(/Response\.Write\(\"\\r\\n\"\);\n/igm,"");
}

//****************************************************
//@DESCRIPTION:	parse page tag. i will call function 'CreatePageList' to create page string,if you do not define function property
//****************************************************
MoAspEnginerView.prototype.parsePage=function(){
	var matches,match,loopname,vbscript,pageurl,func,attrs,nloopname
	var regexp =/\<page ([\s\S]+?)>([\s\S]*?)\<\/page>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		attrs = F.readAttrs(match[1]);
		if(attrs.getter__("for")!=""){
			this.mvarDicts["EOF_OF_" + attrs.getter__("for")] = match[2];
			this.Content = F.replace(this.Content,match.value,"<page " + match[1] + "/>")
		}
	}
	regexp = /\<page ([\s\S]+?)\/>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		attrs = F.readAttrs(match[1]);
		if(attrs.getter__("for")!=""){
			loopname = attrs.getter__("for");
			nloopname = loopname;
			pageurl = attrs.getter__("url");
			func = attrs.getter__("function");
			if(func=="") func = "CreatePageList";
			if(this.loops.indexOf(";" + loopname + ";")>=0){
				if(!G.MO_COMPILE_STRICT)nloopname = "D__" + loopname;
				this.Content = F.replace(this.Content,match[0],"<?MoAsp if(Mo.Assigns.hasOwnProperty(\"" + loopname + "\")){ MoAsp?><?MoAsp __Mo__.Echo(" + func + "(\"" + pageurl + "\"," + nloopname + ".recordcount," + nloopname + ".pagesize," + nloopname  + ".currentpage)); MoAsp?><?MoAsp } MoAsp?>");
			}else{
				this.Content = F.replace(this.Content,match[0],"");
			}
		}
	}
}
//****************************************************
//@DESCRIPTION:	get all loop tags.
//****************************************************
MoAspEnginerView.prototype.getLoops=function(name){
	if(name.constructor==Array){
		for(var i=0;i<name.length;i++){
			this.getLoops(name[i]);
		}
		return;
	}
	var matches,match,loopname,attrs
	var regexp = new RegExp("\\<" + name + " ([\\s\\S]+?)\\>","igm");
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		attrs = F.readAttrs(match[1]);
		if(attrs.getter__("name")!="") this.loops += attrs.getter__("name") + ";"
	}
}

//****************************************************
//@DESCRIPTION:	parse loop tag. All looped data is an instance of list(DataTable) which is defined in 'Mo.Extend.asp'
//****************************************************
MoAspEnginerView.prototype.parseLoop=function(){
	var matches,match,loopname,vbscript,attrs,varname;
	var regexp = /\<loop ([\s\S]+?)\>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		attrs = F.readAttrs(match[1]);
		if(attrs.getter__("name")!=""){
			loopname = attrs.getter__("name");
			varname = loopname;
			if(!G.MO_COMPILE_STRICT)varname = "D__" + loopname;
			vbscript = "<?MoAsp ";
			if(!G.MO_COMPILE_STRICT){
				vbscript += "if(Mo.Assigns.hasOwnProperty(\"" + loopname + "\")){\r\n"
				vbscript += varname + " = Mo.Assigns[\"" + loopname + "\"];\r\n";
			}
			vbscript += varname + ".reset();\r\n";
			var contenteof = attrs.getter__("eof");
			if(contenteof!="")contenteof = F.replace(F.replace(contenteof,"&gt;",">"),"&lt;","<");
			if(this.mvarDicts.hasOwnProperty("EOF_OF_" + loopname))contenteof = this.mvarDicts["EOF_OF_" + loopname];
			contenteof = F.replace(F.replace(contenteof,"\"","\\\""),"\r\n","");
			if(contenteof!="")vbscript += "if(" + varname + ".eof()){\r\n__Mo__.Echo(\"" + contenteof + "\");\r\n}\r\n";
			vbscript += "K__" + loopname + "=" + varname + ".pagesize *(" + varname + ".currentpage-1);\r\n";
			//vbscript += "while(!" + varname + ".eof()){\r\nK__" + loopname + "=K__" + loopname + "+1;\r\nC__" + loopname + " =  " + varname + ".read(); MoAsp?>"
			vbscript += varname + ".each(function(C__" + loopname + "){\r\nK__" + loopname + "=K__" + loopname + "+1;\r\n MoAsp?>"
			this.Content = F.replace(this.Content,match[0],vbscript);
			this.Content = F.replace(this.Content,"{$" + loopname + ".Key__}","<?MoAsp __Mo__.Echo(K__" + loopname + "); MoAsp?>");
			var m_,ms_;
			var nregexp = new RegExp("\\{\\$" + loopname + "\\.(.+?)\\}","igm");
			ms_ = F.string.matches(this.Content,nregexp);
			while(ms_.length>0){
				m_ = ms_.pop();
				var k = m_[1],v;
				if(k.indexOf(":")<0){
					if(G.MO_COMPILE_STRICT){
						this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(C__" + loopname + "." + k + "); MoAsp?>")
					}else{
						this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(C__" + loopname + ".getter__(\"" + k + "\")); MoAsp?>")
					}
				}else{
					var c = k.substr(k.indexOf(":")+1);
					k = k.substr(0,k.indexOf(":"));
					if(G.MO_COMPILE_STRICT){
						this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(" + F.replace(this.parseFormatVari(c),"{{k}}","C__" + loopname + "." + k) + "); MoAsp?>")
					}else{
						this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(" + F.replace(this.parseFormatVari(c),"{{k}}","C__" + loopname + ".getter__(\"" + k + "\")") + "); MoAsp?>")
					}
				}
			}
		}
	}
	if(!G.MO_COMPILE_STRICT){
		this.Content = F.replace(this.Content,"</loop>","<?MoAsp });} MoAsp?>")	
	}else{
		this.Content = F.replace(this.Content,"</loop>","<?MoAsp }); MoAsp?>")	
	}
}

//****************************************************
//@DESCRIPTION:	parse foreach tag.
//****************************************************
MoAspEnginerView.prototype.parseForeach=function(){
	var matches,match,loopname,vbscript,typ,basezero,attrs;
	var regexp = /\<foreach ([\s\S]+?)\>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		match = matches.pop();
		var m_,ms_, k,v,c;
		attrs = F.readAttrs(match[1]);
		if(attrs.getter__("name")!=""){
			loopname = attrs.getter__("name");
			typ = attrs.getter__("type");
			vbscript = "<?MoAsp ";
			if(!G.MO_COMPILE_STRICT)vbscript += "if(Mo.Assigns.hasOwnProperty(\"" + loopname + "\")){\r\n";
			if(!G.MO_COMPILE_STRICT){
				vbscript += "var D__" + loopname + "=Mo[\"" + loopname + "\"];\r\nfor(var C__" + loopname + " in D__" + loopname + "){\r\nif(!D__" + loopname + ".hasOwnProperty(C__" + loopname + "))continue;\r\n MoAsp?>\r\n"
			}else{
				vbscript += "for(var C__" + loopname + " in " + loopname + "){\r\nif(!" + loopname + ".hasOwnProperty(C__" + loopname + "))continue;\r\n MoAsp?>\r\n"
			}
			this.Content = F.replace(this.Content,match[0],vbscript);
			this.Content = F.replace(this.Content,"{$" + loopname + ".Key__}","<?MoAsp __Mo__.Echo(C__" + loopname + "); MoAsp?>");
			var nregexp = new RegExp("\\{\\$" + loopname + "(\\:(.+?))?\\}","igm");
			ms_ = F.string.matches(this.Content,nregexp);
			while(ms_.length>0){
				m_ = ms_.pop();
				k = m_[2];
				if(k==""){
					this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(D__" + loopname + "[C__" + loopname + "]); MoAsp?>");
				}else{
					this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(" + F.replace(this.parseFormatVari(k),"{{k}}","D__" + loopname + "[C__" + loopname + "]") + "); MoAsp?>");
				}
			}
		}
	}
	if(!G.MO_COMPILE_STRICT){
		this.Content = F.replace(this.Content,"</foreach>","<?MoAsp }} MoAsp?>")	
	}else{
		this.Content = F.replace(this.Content,"</foreach>","<?MoAsp } MoAsp?>")
	}
}	

//****************************************************
//@DESCRIPTION:	parse switch tag
//****************************************************
MoAspEnginerView.prototype.parseSwitch=function(){
	var matches,m_,attrs;
	var regexp = /<switch ([\s\S]+?)>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[1]);
		if(attrs.getter__("name")!="")this.Content = F.replace(this.Content,m_[0],"<?MoAsp switch(" + this.parseAssign(attrs.getter__("name")) + "){ MoAsp?>");
	}
	this.parseCase();
};

//****************************************************
//@DESCRIPTION:	parse case tag
//****************************************************
MoAspEnginerView.prototype.parseCase=function(){
	var matches,m_,t,quto,attrs;
	var regexp = /<case ([\s\S]+?)\/>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[1]);
		quto="\"";
		if("|bool|number|money|date|assign|".indexOf("|" + attrs.getter__("type") + "|")>0)quto="";
		this.Content = F.replace(this.Content,m_[0],"<?MoAsp case " + quto + attrs.getter__("value") + quto + ": MoAsp?>");
	}
};
	
//****************************************************
//@DESCRIPTION:	parse expression
//****************************************************
MoAspEnginerView.prototype.parseExpression=function(){
	var matches,m_,expression;
	var regexp = /<expression ([\s\S]+?)>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		expression = this.parseExpressionComponent(m_[1]);
		if(expression=="") F.exit("template parse error,please check 'expression' tag。");
		this.Content = F.replace(this.Content,m_[0],"<?MoAsp if(" + expression + "){\r\n MoAsp?>");
	}
	this.Content = F.string.replace(this.Content,/<(and|or)(.+?)\/>/igm,"")
};
MoAspEnginerView.prototype.parseExpressionElse=function(){
	var matches,m_,expression;
	var regexp = /<else ([\s\S]+?) \/>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		expression = this.parseExpressionComponent(m_[1])
		if(expression=="") F.exit("template parse error,please check 'expression' tag。");
		this.Content = F.replace(this.Content,m_[0],"<?MoAsp }else if(" + expression + "){ MoAsp?>");
	}
};
MoAspEnginerView.prototype.parseExpressionComponent=function(compare){
	var expression="",n_,v_,varmatches,j_,quto,vv_,matches;
	var regexp = new RegExp("\\b(and|or|group)\\=\\\"(.+?)\\\"","igm");
	matches = F.string.matches(compare,regexp);
	while(matches.length>0){
		n_ = matches.pop();
		if(n_[1]=="and" || n_[1]=="or"){
			v_ = n_[2];
			varmatches = /^(.+?)((\s)(\+|\-|\*|\/|%)(\s)([\d\.e\+]+))?(\s)(gt|lt|ngt|nlt|eq|neq)(\s)(.+?)((\s)as(\s)(bool|number|money|date|assign))?$/i.exec(v_);
			if(varmatches){
				quto="\"";
				vv_ = varmatches[10];
				if(expression!="")expression += " " + (n_[1]=="and"?"&&":"||") + " "
				if(F.string.startWith(varmatches[8],"n"))expression += " !";
				if(F.string.endWith(varmatches[8],"t"))quto="";
				if(vv_=="Empty"){
					expression += " is_empty("
					expression += this.parseAssign(varmatches[1]);
					if(varmatches[2]!="") expression += varmatches[2];
					expression += ") ";
				}else{
					expression += this.parseAssign(varmatches[1]);
					if(varmatches[2]!="")expression += varmatches[2];
					if(varmatches[8]=="gt")expression += " > ";
					if(varmatches[8]=="lt")expression += " < ";
					if(varmatches[8]=="ngt")expression += " > ";
					if(varmatches[8]=="nlt")expression += " < ";
					if(varmatches[8]=="eq")expression += " == ";
					if(varmatches[8]=="neq")expression += " == ";
					if(varmatches[11]!=""){
						quto="";
						if(varmatches[14]=="assign")vv_ = this.parseAssign(vv_);
					}
					if(F.string.test(vv_,/^\{\$(.+?)\}$/i)){
						vv_ = this.parseAssign(F.string.replace(vv_,/^\{\$(.+?)\}$/i,"$1"));
						quto="";
					}
					expression += quto + vv_ + quto;
				}
			}
		}else{
			var group = n_[2];
			var groupmatches = (new RegExp("<(and|or) name\\=\\\"" + group + "\\\"(.+?) \\/>","igm")).exec(this.Content);
			if(groupmatches){
				expression += " " + groupmatches[1] + " (" + this.parseExpressionComponent(groupmatches[2]) + ") "
			}
		}
	}
	return expression;
}
	
//****************************************************
//@DESCRIPTION:	parse compare tag(gt,lt,ngt,nlt,eq,neq)
//@PARAM:	tag [String] : gt/lt/ngt/nlt/eq/neq
//@PARAM:	comp [String] : >/</= . The symbol which i will compare with
//@PARAM:	no [String] : not/[blank]. The value 'not' follows the type of the tag.
//****************************************************
MoAspEnginerView.prototype.parseCompare=function(tag){
	if(tag.constructor==Array){
		for(var i=0;i<tag.length;i++){
			this.parseCompare(tag[i]);
		}
		return;
	}
	var matches,m_,attrs;
	var regexp = new RegExp("<" + tag + " ([\\s\\S]+?)>","igm");
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[1]);
		if(attrs.getter__("name")!=""){
			var newexpression = attrs.getter__("name") + " " + tag + " " + attrs.getter__("value");
			if(attrs.getter__("type")!="")newexpression += " as " + attrs.getter__("type");
			this.Content = F.replace(this.Content,m_[0],"<expression and=\"" + newexpression + "\">");
		}
	}
};

//****************************************************
//@DESCRIPTION:	parse empty tag
//****************************************************
MoAspEnginerView.prototype.parseEmpty=function(){
	var matches,m_,l,k,v,s,attrs;
	var regexp=/<(n)?empty ([\s\S]+?)>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[2]);
		if(attrs.getter__("name")!=""){
			s="";
			if(m_[1]=="n")s=" !";
			this.Content = F.replace(this.Content,m_[0],"<?MoAsp if(" + s + "is_empty(" + this.parseAssign(attrs.getter__("name")) + ")){\r\n MoAsp?>")
		}
	}
};

//****************************************************
//@DESCRIPTION:	parse assign tag
//****************************************************
MoAspEnginerView.prototype.parseAssignName=function(){
	var matches,m_,attrs;
	var regexp=/<assign ([\s\S]+?)\/>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[1]);
		if(attrs.getter__("name")!="")this.Content = F.replace(this.Content,m_[0],"<?MoAsp Mo.assign(\"" + attrs.getter__("name") + "\",\"" + F.string.replace(attrs.getter__("value"),/\"/igm,"\\\"") + "\"); MoAsp?>");
	}
};

//****************************************************
//@DESCRIPTION:	parse source include tag(css/js/load)
//****************************************************
MoAspEnginerView.prototype.parseSource=function(){
	var matches,m_,id,cs,ext,attrs,filepath;
	var regexp=/<(js|css|load) ([\s\S]+?) \/>/igm;
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		attrs = F.readAttrs(m_[2]);
		filepath = "";
		if(attrs.getter__("file")!="")filepath = attrs.getter__("file");
		if(attrs.getter__("href")!="")filepath = attrs.getter__("href");
		if(attrs.getter__("src")!="")filepath = attrs.getter__("src");
		if(filepath!=""){
			id="";
			cs="";
			if(filepath.indexOf(".")>0)ext = filepath.substr(filepath.lastIndexOf("."));
			if(attrs.getter__("id")!="")id=" id=\"" + attrs.getter__("id") + "\"";
			if(attrs.getter__("charset")!="")cs=" charset=\"" + attrs.getter__("charset") + "\"";
			if(m_[1]=="js" || ext==".js"){
				this.Content = F.replace(this.Content,m_[0],"<s"+"cript type=\"text/javascript\" src=\"" + filepath + "\"" + id + cs + "></scrip"+"t>");
			}else{
				this.Content = F.replace(this.Content,m_[0],"<link rel=\"stylesheet\" type=\"text/css\" href=\"" + filepath + "\"" + id + cs + " />");
			}
		}
	}
};

//****************************************************
//@DESCRIPTION:	parse single variable
//@PARAM:	chars [Variant] : #/@/[blank]
//****************************************************
MoAspEnginerView.prototype.parseVari=function(chars){
	if(chars.constructor==Array){
		for(var i=0;i<chars.length;i++){
			this.parseVari(chars[i]);
		}
		return;
	}
	var matches,m_;
	var regexp=new RegExp("\\{\\$" + chars + "(.+?)\\}","igm");
	matches = F.string.matches(this.Content,regexp);
	while(matches.length>0){
		m_ = matches.pop();
		if(chars=="#"){
			this.Content = F.replace(this.Content,m_[0],"\" + " + this.parseAssign(m_[1]) + " + \"")
		}else if(chars=="@"){
			this.Content = F.replace(this.Content,m_[0],this.parseAssign(m_[1]))
		}else{
			this.Content = F.replace(this.Content,m_[0],"<?MoAsp __Mo__.Echo(" + this.parseAssign(m_[1]) + ");MoAsp?>")
		}
	}
};

//****************************************************
//@DESCRIPTION:	parse assign variable as asp code
//@PARAM:	key [Variant] : variable need to be parsed
//****************************************************
MoAspEnginerView.prototype.parseAssign=function(key){
	var k=key,v,m_,ms_,l,c,cf,kn;
	var ms_ = /^([\w\.]+?)((\s)(\+|\-|\*|\/|%)(\s)([\d\.e\+]+))?(\:(.+?))?$/i.exec(key);
	if(ms_){
		l = ms_[1];
		c = ms_[8];
		if(c==""){
			var rv="";
			if(l.indexOf(".")<=0){
				if(G.MO_COMPILE_STRICT)
					rv = l;
				else
					rv = "Mo.value(\"" + l + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"c.") || F.string.startWith(l.toLowerCase(),"g.")){
				rv = l.substr(2);
			}else if(F.string.startWith(l.toLowerCase(),"mo.session.")){
				rv = "F.session(\"" + l.substr(11) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.get.int.")){
				rv = "F.get.int(\"" + l.substr(11) + "\",0)";
			}else if(F.string.startWith(l.toLowerCase(),"mo.post.int.")){
				rv = "F.post.int(\"" + l.substr(12) + "\",0)";
			}else if(F.string.startWith(l.toLowerCase(),"mo.get.")){
				rv = "F.get(\"" + l.substr(7) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.post.")){
				rv = "F.post(\"" + l.substr(8) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.cookie.")){
				rv = "F.cookie(\"" + l.substr(10) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.server.")){
				rv = "F.server(\"" + l.substr(10) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.l.")){
				rv = "Mo.L(\"" + l.substr(5) + "\")";
			}else if(F.string.startWith(l.toLowerCase(),"mo.c.")){
				cf = l.substr(5);
				if(cf.IndexOf(".")>0){
					rv = "Mo.C(\"" + cf.substr(0,cf.indexOf(".")) + "\")." + cf.substr(cf.indexOf(".")+1);
				}
			}else if(F.string.startWith(l.toLowerCase(),"mo.a.")){
				cf = l.substr(5);
				if(cf.IndexOf(".")>0){
					rv = "Mo.A(\"" + cf.substr(0,cf.indexOf(".")) + "\")." + cf.substr(cf.indexOf(".")+1);
				}
			}else{
				k = l.substr(l.indexOf(".")+1);
				l = l.substr(0,l.indexOf("."));
				if(this.loops.indexOf(";" + l + ";")>=0){
					if(k=="Key__"){
						rv = "C__" + l;
					}else{
						if(G.MO_COMPILE_STRICT)
							rv = "C__" + l + "." + k;
						else
							rv = "C__" + l + ".getter__(\"" + k + "\")";
					}
				}else{
					if(G.MO_COMPILE_STRICT)
						rv = l + "." + k;
					else
						rv = "Mo.values(\"" + l + "\",\"" + k + "\")";
				}
			}
			if(rv!="")rv += ms_[2];
			return rv;
		}else{
			var parsed = this.parseFormatVari(c);
			if(l.indexOf(".")<=0){
				if(G.MO_COMPILE_STRICT){
					return parsed.replace("{{k}}",l+ ms_[2]);
				}else{
					return parsed.replace("{{k}}","Mo.value(\"" + l + "\")"+ ms_[2]);
				}
			}else if(F.string.startWith(l.toLowerCase(),"c.") || F.string.startWith(l.toLowerCase(),"g.")){
				return parsed.replace("{{k}}",l.substr(2));
			}else if(F.string.startWith(l.toLowerCase(),"mo.session.")){
				return parsed.replace("{{k}}","F.session(\"" + l.substr(11) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.get.int.")){
				return parsed.replace("{{k}}","F.get.int(\"" + l.substr(11) + "\",0)");
			}else if(F.string.startWith(l.toLowerCase(),"mo.post.int.")){
				return parsed.replace("{{k}}","F.post.int(\"" + l.substr(12) + "\",0)");
			}else if(F.string.startWith(l.toLowerCase(),"mo.get.")){
				return parsed.replace("{{k}}","F.get(\"" + l.substr(7) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.post.")){
				return parsed.replace("{{k}}","F.post(\"" + l.substr(8) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.cookie.")){
				return parsed.replace("{{k}}","F.cookie(\"" + l.substr(10) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.server.")){
				return parsed.replace("{{k}}","F.server(\"" + l.substr(10) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.l.")){
				return parsed.replace("{{k}}","Mo.L(\"" + l.substr(5) + "\")");
			}else if(F.string.startWith(l.toLowerCase(),"mo.c.")){
				cf = l.substr(5);
				if(cf.IndexOf(".")>0){
					return parsed.replace("{{k}}","Mo.C(\"" + cf.substr(0,cf.indexOf(".")) + "\")." + cf.substr(cf.indexOf(".")+1));
				}
			}else if(F.string.startWith(l.toLowerCase(),"mo.a.")){
				cf = l.substr(5);
				if(cf.IndexOf(".")>0){
					return parsed.replace("{{k}}","Mo.A(\"" + cf.substr(0,cf.indexOf(".")) + "\")." + cf.substr(cf.indexOf(".")+1));
				}
			}else{
				k = l.substr(l.indexOf(".")+1);
				l = l.substr(0,l.indexOf("."));
				if(this.loops.indexOf(";" + l + ";")>=0){
					if(G.MO_COMPILE_STRICT)
						return parsed.replace("{{k}}","C__" + l + "." + k+ ms_[2]);
					else
						return parsed.replace("{{k}}","C__" + l + ".getter__(\"" + k + "\")"+ ms_[2]);
				}else{
					if(G.MO_COMPILE_STRICT)
						return parsed.replace("{{k}}",l + "." + k+ ms_[2]);
					else
						return parsed.replace("{{k}}","Mo.values(\"" + l + "\",\"" + k + "\")"+ ms_[2]);
				}
			}
		}
	}
};

//****************************************************
//@DESCRIPTION:	parse special variable(function or inner object ref)
//@PARAM:	format [String] : format string
//****************************************************
MoAspEnginerView.prototype.parseFormatVari=function(format){
	if(format=="") return "";
	var func=format,vars="",ret="";
	if(func.indexOf("=")>0){
		vars ="," + func.substr(func.indexOf("=")+1);
		func = func.substr(0,func.indexOf("="));
	}
	var funcs=func.split(".");
	if(funcs.length==3 && funcs[0].toLowerCase()=="mo"){
		func = "Mo.Static(\"" + funcs[1] + "\")." + funcs[2];
	}else if(funcs.length==4 && funcs[0].toLowerCase()=="mo" && funcs[1].toLowerCase()=="a"){
		func = "Mo.A(\"" + funcs[2] + "\")." + funcs[3];
	}else if(func.length>2 && F.string.startWith(func.toLowerCase(),"f.")){
		func = "F." + func.substr(2);
	}
	if(("," + G.DISABLED_FUNCTIONS.toLowerCase() + ",").indexOf("," + func.toLowerCase() + ",")>=0){
		return "\"disabled function:" + func + "\"";
	}
	ret=func + "({{k}}" + vars + ")";
	if(F.string.endWith(vars,"...")){
		vars = vars.substr(0,vars.length-3);
		if(vars.substr(0,1)==",") vars = vars.substr(1);
		ret = func + "(" + vars + "{{k}})";
	}else if(vars.indexOf(",...,")>=0){
		vars = vars.replace(",...,",",{{k}},");
		if(vars.substr(0,1)==",") vars = vars.substr(1);
		ret = func + "(" + vars + ")";
	}
	return ret;
};

MoAspEnginerView.prototype.parseMoAsAsp=function(){
	var m_,ms_,id;
	var regexp = /<\?MoAsp([\s\S]*?)MoAsp\?>/igm;
	var ms_ = F.string.matches(this.Content,regexp);
	while(ms_.length>0){
		m_=ms_.pop();
		id = this.getRndid();
		this.mvarDicts[id] = m_[0];
		this.Content = F.replace(this.Content,m_[0],"\r\n<?MoAsp" + id + "MoAsp?>\r\n");
	}
	this.Content = F.string.trim(this.Content);
	this.Content = F.string.replace(this.Content,/(\r\n){2,}/igm,"\r\n");
	this.Content = F.string.replace(this.Content,/\"/igm,"\\\"");
	this.Content = F.string.replace(this.Content,/(^|\r\n)/igm,"$1__Mo__.Echo(\"");
	this.Content = F.string.replace(this.Content,/($|\r\n)/igm,"\");$1" );
	regexp = /__Mo__\.Echo\(\"<\?MoAsp([\w]+?)MoAsp\?>\"\);/igm;
	var ms_ = F.string.matches(this.Content,regexp);
	while(ms_.length>0){
		m_=ms_.pop();
		id = m_[1];
		this.Content = F.replace(this.Content,m_[0],this.mvarDicts[id]);
	}
	this.Content = F.string.replace(this.Content,/<\?MoAsp /igm,"");
	this.Content = F.string.replace(this.Content,/(\s*)MoAsp\?>/igm,"");
	//this.Content = replace(this.Content,"""" + vbcrlf + "__Mo__.Echo ""","")
	//this.Content = replace(this.Content,"""" + vbcrlf + "__Mo__.Echo ",""" + ")
};
	
MoAspEnginerView.prototype.getRndid=function(){
	var rid = F.random.word(10);
	while(this.mvarDicts.hasOwnProperty(rid)){
		rid = F.random.word(10);
	}
	return rid;
};
</script>