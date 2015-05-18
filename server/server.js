var express = require('express');
var path = require('path');
var fs = require('fs');
var mime = require('mime');
var request = require('request');


var localhost = "127.0.0.1";
var port = 1337;

var app = express();
app.use(express.static(__dirname + "/public")); //use static files in ROOT/public folder

app.get("/", function(request, response){ //root dir
    response.send("Hello!!");
});
var ads={};
var locals=[];
var adLocal=false;
var readyLocal=false;
fs.readdir(__dirname +"/public/ads", function(err,fnames){
	console.log(fnames);
	fnames.forEach(function(ad){
		var ftype=ad.split(".").pop();
		if(!(ftype in ads)){
			ads[ftype]={"mime":mime.lookup(ad),"list":[]};
		}
		ads[ftype].list.push(path.join(__dirname,"public/ads",ad));
	});
	console.log(ads);
	Object.keys(ads).forEach(function(adType){
		app.get("/nextad."+adType, function(req, res){ //send the next ad in the directory
			if(adLocal){
				adLocal=false;
				request('http://freegeoip.net//json//'+req.ip, function (error, response, body) {
					var db=ads;
					if (!error && response.statusCode == 200) {
						var metroCode=JSON.parse(body).metro_code;
						if(metroCode in locals)db=locals[metroCode];	
					}
					sendAd(res,db,adType);
				});
			}else {
				sendAd(res,ads,adType);
				if(readyLocal)adLocal=true;
			}
		});
	});
});
fs.readdir(__dirname +"/public/locals", function(err,folds){
	folds.forEach(function(fold){
		if(!(fold in locals))locals[fold]={};
		fs.readdir(path.join(__dirname,"public/locals",fold), function(err,fnames){
			if(err)console.log(err);
			else{
				fnames.forEach(function(ad){
					var ftype=ad.split(".").pop();
					if(!(ftype in locals[fold])){
						locals[fold][ftype]={"mime":mime.lookup(ad),"list":[]};
					}
					locals[fold][ftype].list.push(path.join(__dirname,"public/locals",fold,ad));
				});
			}
		});
	});
	readyLocal=true;
});
function sendAd(res,dataBase,adType){
	var currentad=dataBase[adType].list.shift();
	dataBase[adType].list.push(currentad);
	res.contentType(dataBase[adType].mime);
	res.sendFile(currentad);
	console.log("Sent ad -- "+currentad);
}
	


app.listen(port);

