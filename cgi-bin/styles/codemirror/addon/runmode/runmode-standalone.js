(function(){function z(a,b,c){b||(b={});for(var d in a)!a.hasOwnProperty(d)||!1===c&&b.hasOwnProperty(d)||(b[d]=a[d]);return b}function q(a,b,c,d,e){null==b&&(b=a.search(/[^\s\u00a0]/),-1==b&&(b=a.length));d=d||0;for(e=e||0;;){var h=a.indexOf("\t",d);if(0>h||h>=b)return e+(b-d);e+=h-d;e+=c-e%c;d=h+1}}function A(){}function u(a){if("string"==typeof a&&m.hasOwnProperty(a))a=m[a];else if(a&&"string"==typeof a.name&&m.hasOwnProperty(a.name)){var b=m[a.name];"string"==typeof b&&(b={name:b});var c=b;Object.create?
c=Object.create(c):(A.prototype=c,c=new A);a&&z(a,c);a=c;a.name=b.name}else{if("string"==typeof a&&/^[\w\-]+\/[\w\-]+\+xml$/.test(a))return u("application/xml");if("string"==typeof a&&/^[\w\-]+\/[\w\-]+\+json$/.test(a))return u("application/json")}return"string"==typeof a?{name:a}:a||{name:"null"}}function B(a,b){b=u(b);var c=x[b.name];if(!c)return B(a,"text/plain");a=c(a,b);if(n.hasOwnProperty(b.name)){c=n[b.name];for(var d in c)c.hasOwnProperty(d)&&(a.hasOwnProperty(d)&&(a["_"+d]=a[d]),a[d]=c[d])}a.name=
b.name;b.helperType&&(a.helperType=b.helperType);if(b.modeProps)for(var e in b.modeProps)a[e]=b.modeProps[e];return a}var f=function(a,b,c){this.pos=this.start=0;this.string=a;this.tabSize=b||8;this.lineStart=this.lastColumnPos=this.lastColumnValue=0;this.lineOracle=c};f.prototype.eol=function(){return this.pos>=this.string.length};f.prototype.sol=function(){return this.pos==this.lineStart};f.prototype.peek=function(){return this.string.charAt(this.pos)||void 0};f.prototype.next=function(){if(this.pos<
this.string.length)return this.string.charAt(this.pos++)};f.prototype.eat=function(a){var b=this.string.charAt(this.pos);if("string"==typeof a?b==a:b&&(a.test?a.test(b):a(b)))return++this.pos,b};f.prototype.eatWhile=function(a){for(var b=this.pos;this.eat(a););return this.pos>b};f.prototype.eatSpace=function(){for(var a=this.pos;/[\s\u00a0]/.test(this.string.charAt(this.pos));)++this.pos;return this.pos>a};f.prototype.skipToEnd=function(){this.pos=this.string.length};f.prototype.skipTo=function(a){a=
this.string.indexOf(a,this.pos);if(-1<a)return this.pos=a,!0};f.prototype.backUp=function(a){this.pos-=a};f.prototype.column=function(){this.lastColumnPos<this.start&&(this.lastColumnValue=q(this.string,this.start,this.tabSize,this.lastColumnPos,this.lastColumnValue),this.lastColumnPos=this.start);return this.lastColumnValue-(this.lineStart?q(this.string,this.lineStart,this.tabSize):0)};f.prototype.indentation=function(){return q(this.string,null,this.tabSize)-(this.lineStart?q(this.string,this.lineStart,
this.tabSize):0)};f.prototype.match=function(a,b,c){if("string"==typeof a){var d=function(h){return c?h.toLowerCase():h},e=this.string.substr(this.pos,a.length);if(d(e)==d(a))return!1!==b&&(this.pos+=a.length),!0}else{if((a=this.string.slice(this.pos).match(a))&&0<a.index)return null;a&&!1!==b&&(this.pos+=a[0].length);return a}};f.prototype.current=function(){return this.string.slice(this.start,this.pos)};f.prototype.hideFirstChars=function(a,b){this.lineStart+=a;try{return b()}finally{this.lineStart-=
a}};f.prototype.lookAhead=function(a){var b=this.lineOracle;return b&&b.lookAhead(a)};f.prototype.baseToken=function(){var a=this.lineOracle;return a&&a.baseToken(this.pos)};var x={},m={},n={},C={__proto__:null,modes:x,mimeModes:m,defineMode:function(a,b){2<arguments.length&&(b.dependencies=Array.prototype.slice.call(arguments,2));x[a]=b},defineMIME:function(a,b){m[a]=b},resolveMode:u,getMode:B,modeExtensions:n,extendMode:function(a,b){a=n.hasOwnProperty(a)?n[a]:n[a]={};z(b,a)},copyState:function(a,
b){if(!0===b)return b;if(a.copyState)return a.copyState(b);a={};for(var c in b){var d=b[c];d instanceof Array&&(d=d.concat([]));a[c]=d}return a},innerMode:function(a,b){for(var c;a.innerMode;){c=a.innerMode(b);if(!c||c.mode==a)break;b=c.state;a=c.mode}return c||{mode:a,state:b}},startState:function(a,b,c){return a.startState?a.startState(b,c):!0}};("undefined"!==typeof globalThis?globalThis:window).CodeMirror={};CodeMirror.StringStream=f;for(var D in C)CodeMirror[D]=C[D];CodeMirror.defineMode("null",
function(){return{token:function(a){return a.skipToEnd()}}});CodeMirror.defineMIME("text/plain","null");CodeMirror.registerHelper=CodeMirror.registerGlobalHelper=Math.min;CodeMirror.splitLines=function(a){return a.split(/\r?\n|\r/)};CodeMirror.countColumn=q;CodeMirror.defaults={indentUnit:2};(function(a){"object"==typeof exports&&"object"==typeof module?a(require("../../lib/codemirror")):"function"==typeof define&&define.amd?define(["../../lib/codemirror"],a):a(CodeMirror)})(function(a){a.runMode=
function(b,c,d,e){c=a.getMode(a.defaults,c);var h=e&&e.tabSize||a.defaults.tabSize;if(d.appendChild){var G=/MSIE \d/.test(navigator.userAgent)&&(null==document.documentMode||9>document.documentMode),v=d,r=0;v.textContent="";d=function(g,E){if("\n"==g)v.appendChild(document.createTextNode(G?"\r":g)),r=0;else{for(var t="",k=0;;){var w=g.indexOf("\t",k);if(-1==w){t+=g.slice(k);r+=g.length-k;break}else{r+=w-k;t+=g.slice(k,w);k=h-r%h;r+=k;for(var F=0;F<k;++F)t+=" ";k=w+1}}E?(g=v.appendChild(document.createElement("span")),
g.className="cm-"+E.replace(/ +/g," cm-"),g.appendChild(document.createTextNode(t))):v.appendChild(document.createTextNode(t))}}}var y=a.splitLines(b);b=e&&e.state||a.startState(c);var p=0;for(e=y.length;p<e;++p){p&&d("\n");var l=new a.StringStream(y[p],null,{lookAhead:function(g){return y[p+g]},baseToken:function(){}});for(!l.string&&c.blankLine&&c.blankLine(b);!l.eol();){var H=c.token(l,b);d(l.current(),H,p,l.start,b,c);l.start=l.pos}}}})})();
