﻿/*
** File: oauth.js
** Usage: create oauth(2.0) request. you know it !
** About: 
**		support@mae.im
*/

function $oauth(client_id, client_secret,redirect_uri){
	this.table=[];
	this.client_id = client_id||"";
	this.redirect_uri = redirect_uri||"";
	this.client_secret = client_secret||"";
	this.debug={};
}
$oauth.fn = $oauth.prototype;
$oauth.fn.toString=function(){
	return "OAUTH 2.0($oauth 1.0) BY Anlige";	
};
$oauth.fn.getAuthorizationUrl = function(authorization_url){
	var url = authorization_url + "?client_id=" + F.encode(this.client_id) + "&response_type=code";
	if(this.redirect_uri!="") url += "&redirect_uri=" + F.encode(this.redirect_uri);
	var data = this.APISTring("utf-8")
	if(data!="") url += "&" + data;
	return url;
}
$oauth.fn.getAccessToken = function(access_token_url, code , method, format){
	if(!format){format = "text";}
	if(!method){method = "GET";}
	var data = "grant_type=authorization_code&code=" + F.encode(code)
	if(this.redirect_uri!="") data += "&redirect_uri=" + F.encode(this.redirect_uri);
	if(this.client_id!="") data += "&client_id=" + F.encode(this.client_id);
	if(this.client_secret!="") data += "&client_secret=" + F.encode(this.client_secret);
	var data1 = this.APISTring("utf-8")
	if(data1!="") data += "&" + data1;
	return this.SendData(access_token_url,method,data,format);
};

$oauth.fn.RefreshToken = function(refresh_token_url, refresh_token , method, format){
	if(!format){format = "text";}
	if(!method){method = "GET";}
	var data = "grant_type=refresh_token&client_id=" + F.encode(this.client_id) + "&refresh_token=" + F.encode(refresh_token) + "&client_secret=" + F.encode(this.client_secret)
	if(this.redirect_uri!="") data += "&redirect_uri=" + F.encode(this.redirect_uri);
	if(this.client_id!="") data += "&client_id=" + F.encode(this.client_id);
	if(this.client_secret!="") data += "&client_secret=" + F.encode(this.client_secret);
	var data1 = this.APISTring("utf-8")
	if(data1!="") data += "&" + data1;
	return this.SendData(refresh_token_url,method,data,format);
};
$oauth.fn.FetchFromAPI = function(api, method, format){
	format = format || "text";
	method = method || "GET";
	return this.SendData(api,method,this.APISTring("utf-8"),format);
};

$oauth.fn.SendData = function(url,method,data,format){
	F.require("http.request");
	var myhttp = new F.exports.http.request(url,method,data);
	myhttp.autoClearBuffer=false;
	myhttp.send();
	var result;
	if(format=="json"){
		result =myhttp.getjson("utf-8");
	}else if(format=="xml"){
		result =myhttp.getxml("utf-8");
	}else{
		result =myhttp.gettext("utf-8");	
	}
	this.debug["url"]=myhttp.url;
	this.debug["data"]=data;
	myhttp = null;
	return result;	
};

$oauth.fn.Sort = function(order,key){
	if(this.Count()<=0){return ;}
	var isASC = true;
	if(order.toLowerCase()=="asc"){
		isASC=true;
	}else if(order.toLowerCase()=="desc"){
		isASC=false;
	}
	if(key!="key" && key !="value"){key="key";}
	var __temp = null;
	for(var i=0;i<this.Count()-1;i++){
		for(var j=i+1;j<this.Count();j++){
			if(this.table[i][key]>this.table[j][key] == isASC){
				var thevalue=this.table[i];
				this.table[i] = this.table[j];
				this.table[j] = thevalue;
			}
		}
	}
};


$oauth.fn.APISTring = function(charset,split1,split2){
	charset ? charset : (charset="no");
	charset = charset.toLowerCase();
	if(!split1){split1="=";}
	if(!split2 && split2!=""){split2="&";}
	if(this.table.length<=0){return "";}
	var str = "";
	for(var i=0;i< this.table.length;i++){
		if(this.table[i]["value"]==""){continue;}
		var val = this.table[i]["value"];
		if(charset=="gb2312"){
			str += this.table[i]["key"] + split1 + escape(val) + split2;
		}else if(charset=="gbk"){
			str += this.table[i]["key"] + split1 + Server.URLEncode(val) + split2;
		}else if(charset=="no"){
			str += this.table[i]["key"] + split1 + val + split2;
		}else{
			str += this.table[i]["key"] + split1 + F.encode(val) + split2;
		}
	}
	if(str!=""){
		str = str.substr(0,str.length-split2.length);	
	}
	return str;	
};

$oauth.fn.Set = function(key,value,isdefault){
	if(!value){value="";}
	if(!isdefault){isdefault=false;};
	if(this.table.length==0){
		this.table[0]={"key":key,"value":value,"isdefault":isdefault};
	}else{
		var isIn = false;
		for(var i=0;i<this.table.length;i++){
			if(this.table[i]["key"].toLowerCase()==key.toLowerCase()){
				this.table[i]["value"]= value;
				this.table[i]["isdefault"]= isdefault;
				isIn = true;
				break;
			}
		}	
		if(!isIn){
			this.table.push({"key":key,"value":value,"isdefault":isdefault});	
		}
	}
};

$oauth.fn.Add = function(key,value){
	if(!value){value="";}
	if(this.table.length==0){
		this.table[0]={"key":key,"value":value};
	}else{
		var isIn = false;
		for(var i=0;i<this.table.length;i++){
			if(this.table[i]["key"].toLowerCase()==key.toLowerCase()){
				if(this.table[i]["value"]!=""){
					this.table[i]["value"]= this.table[i]["value"] + ", " + value;
				}else{
					this.table[i]["value"]= value;
				}
				isIn = true;
				break;
			}
		}	
		if(!isIn){
			this.table.push({"key":key,"value":value});	
		}
	}
};

$oauth.fn.Count = function(){return this.table.length;};

$oauth.fn.Parm = function(key){
	if(this.Count()<=0){return "";}
	for(var i=0;i<this.Count();i++){
		if(this.table[i]["key"].toLowerCase()==key.toLowerCase()){
			return this.table[i]["value"];
		}	
	}
	return "";
};

$oauth.fn.Remove = function(key){
	if(this.Count()<=0){return;}
	if(!key){this.table=[];return;}
	var ___temp=[];
	for(var i=0;i<this.Count();i++){
		if(this.table[i]["key"].toLowerCase()!=key.toLowerCase()){
			___temp.push(this.table[i]);
		}	
	}
	this.table=___temp;
};
$oauth.fn.rndstr=function(len){
	var slen = "0123456789qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPLKJHGFDSAZXCVBNM";
	var retstr="";
	for(var i=0;i<len;i++){
		retstr+=slen.substr(parseInt(Math.random()*slen.length),1);
	}
	return retstr;
};
return exports.oauth = $oauth;