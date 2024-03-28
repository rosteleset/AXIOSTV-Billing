function copyObj(a,b,c){b||(b={});for(var d in a)!a.hasOwnProperty(d)||!1===c&&b.hasOwnProperty(d)||(b[d]=a[d]);return b}function countColumn(a,b,c,d,e){null==b&&(b=a.search(/[^\s\u00a0]/),-1==b&&(b=a.length));d=d||0;for(e=e||0;;){var g=a.indexOf("\t",d);if(0>g||g>=b)return e+(b-d);e+=g-d;e+=c-e%c;d=g+1}}function nothing(){}function createObj(a,b){Object.create?a=Object.create(a):(nothing.prototype=a,a=new nothing);b&&copyObj(b,a);return a}
var StringStream=function(a,b,c){this.pos=this.start=0;this.string=a;this.tabSize=b||8;this.lineStart=this.lastColumnPos=this.lastColumnValue=0;this.lineOracle=c};StringStream.prototype.eol=function(){return this.pos>=this.string.length};StringStream.prototype.sol=function(){return this.pos==this.lineStart};StringStream.prototype.peek=function(){return this.string.charAt(this.pos)||void 0};StringStream.prototype.next=function(){if(this.pos<this.string.length)return this.string.charAt(this.pos++)};
StringStream.prototype.eat=function(a){var b=this.string.charAt(this.pos);if("string"==typeof a?b==a:b&&(a.test?a.test(b):a(b)))return++this.pos,b};StringStream.prototype.eatWhile=function(a){for(var b=this.pos;this.eat(a););return this.pos>b};StringStream.prototype.eatSpace=function(){for(var a=this.pos;/[\s\u00a0]/.test(this.string.charAt(this.pos));)++this.pos;return this.pos>a};StringStream.prototype.skipToEnd=function(){this.pos=this.string.length};
StringStream.prototype.skipTo=function(a){a=this.string.indexOf(a,this.pos);if(-1<a)return this.pos=a,!0};StringStream.prototype.backUp=function(a){this.pos-=a};StringStream.prototype.column=function(){this.lastColumnPos<this.start&&(this.lastColumnValue=countColumn(this.string,this.start,this.tabSize,this.lastColumnPos,this.lastColumnValue),this.lastColumnPos=this.start);return this.lastColumnValue-(this.lineStart?countColumn(this.string,this.lineStart,this.tabSize):0)};
StringStream.prototype.indentation=function(){return countColumn(this.string,null,this.tabSize)-(this.lineStart?countColumn(this.string,this.lineStart,this.tabSize):0)};StringStream.prototype.match=function(a,b,c){if("string"==typeof a){var d=function(g){return c?g.toLowerCase():g},e=this.string.substr(this.pos,a.length);if(d(e)==d(a))return!1!==b&&(this.pos+=a.length),!0}else{if((a=this.string.slice(this.pos).match(a))&&0<a.index)return null;a&&!1!==b&&(this.pos+=a[0].length);return a}};
StringStream.prototype.current=function(){return this.string.slice(this.start,this.pos)};StringStream.prototype.hideFirstChars=function(a,b){this.lineStart+=a;try{return b()}finally{this.lineStart-=a}};StringStream.prototype.lookAhead=function(a){var b=this.lineOracle;return b&&b.lookAhead(a)};StringStream.prototype.baseToken=function(){var a=this.lineOracle;return a&&a.baseToken(this.pos)};var modes={},mimeModes={};
function defineMode(a,b){2<arguments.length&&(b.dependencies=Array.prototype.slice.call(arguments,2));modes[a]=b}function defineMIME(a,b){mimeModes[a]=b}
function resolveMode(a){if("string"==typeof a&&mimeModes.hasOwnProperty(a))a=mimeModes[a];else if(a&&"string"==typeof a.name&&mimeModes.hasOwnProperty(a.name)){var b=mimeModes[a.name];"string"==typeof b&&(b={name:b});a=createObj(b,a);a.name=b.name}else{if("string"==typeof a&&/^[\w\-]+\/[\w\-]+\+xml$/.test(a))return resolveMode("application/xml");if("string"==typeof a&&/^[\w\-]+\/[\w\-]+\+json$/.test(a))return resolveMode("application/json")}return"string"==typeof a?{name:a}:a||{name:"null"}}
function getMode(a,b){b=resolveMode(b);var c=modes[b.name];if(!c)return getMode(a,"text/plain");a=c(a,b);if(modeExtensions.hasOwnProperty(b.name)){c=modeExtensions[b.name];for(var d in c)c.hasOwnProperty(d)&&(a.hasOwnProperty(d)&&(a["_"+d]=a[d]),a[d]=c[d])}a.name=b.name;b.helperType&&(a.helperType=b.helperType);if(b.modeProps)for(var e in b.modeProps)a[e]=b.modeProps[e];return a}var modeExtensions={};
function extendMode(a,b){a=modeExtensions.hasOwnProperty(a)?modeExtensions[a]:modeExtensions[a]={};copyObj(b,a)}function copyState(a,b){if(!0===b)return b;if(a.copyState)return a.copyState(b);a={};for(var c in b){var d=b[c];d instanceof Array&&(d=d.concat([]));a[c]=d}return a}function innerMode(a,b){for(var c;a.innerMode;){c=a.innerMode(b);if(!c||c.mode==a)break;b=c.state;a=c.mode}return c||{mode:a,state:b}}function startState(a,b,c){return a.startState?a.startState(b,c):!0}
var modeMethods={__proto__:null,modes:modes,mimeModes:mimeModes,defineMode:defineMode,defineMIME:defineMIME,resolveMode:resolveMode,getMode:getMode,modeExtensions:modeExtensions,extendMode:extendMode,copyState:copyState,innerMode:innerMode,startState:startState};exports.StringStream=StringStream;exports.countColumn=countColumn;for(var exported in modeMethods)exports[exported]=modeMethods[exported];require.cache[require.resolve("../../lib/codemirror")]=require.cache[require.resolve("./runmode.node")];
require.cache[require.resolve("../../addon/runmode/runmode")]=require.cache[require.resolve("./runmode.node")];exports.defineMode("null",function(){return{token:function(a){return a.skipToEnd()}}});exports.defineMIME("text/plain","null");exports.registerHelper=exports.registerGlobalHelper=Math.min;exports.splitLines=function(a){return a.split(/\r?\n|\r/)};exports.defaults={indentUnit:2};
(function(a){"object"==typeof exports&&"object"==typeof module?a(require("../../lib/codemirror")):"function"==typeof define&&define.amd?define(["../../lib/codemirror"],a):a(CodeMirror)})(function(a){a.runMode=function(b,c,d,e){c=a.getMode(a.defaults,c);var g=e&&e.tabSize||a.defaults.tabSize;if(d.appendChild){var v=/MSIE \d/.test(navigator.userAgent)&&(null==document.documentMode||9>document.documentMode),p=d,m=0;p.textContent="";d=function(f,t){if("\n"==f)p.appendChild(document.createTextNode(v?"\r":
f)),m=0;else{for(var n="",h=0;;){var q=f.indexOf("\t",h);if(-1==q){n+=f.slice(h);m+=f.length-h;break}else{m+=q-h;n+=f.slice(h,q);h=g-m%g;m+=h;for(var u=0;u<h;++u)n+=" ";h=q+1}}t?(f=p.appendChild(document.createElement("span")),f.className="cm-"+t.replace(/ +/g," cm-"),f.appendChild(document.createTextNode(n))):p.appendChild(document.createTextNode(n))}}}var r=a.splitLines(b);b=e&&e.state||a.startState(c);var l=0;for(e=r.length;l<e;++l){l&&d("\n");var k=new a.StringStream(r[l],null,{lookAhead:function(f){return r[l+
f]},baseToken:function(){}});for(!k.string&&c.blankLine&&c.blankLine(b);!k.eol();){var w=c.token(k,b);d(k.current(),w,l,k.start,b,c);k.start=k.pos}}}});
