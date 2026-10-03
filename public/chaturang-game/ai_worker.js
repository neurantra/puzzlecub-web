(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.iR(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.j(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.dN(b)
return new t(c,this)}:function(){if(t===null)t=A.dN(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.dN(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
dS(a,b,c,d){return{i:a,p:b,e:c,x:d}},
dd(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.dQ==null){A.iG()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.c(A.eB("Return interceptor for "+A.o(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.cX
if(p==null)p=$.cX=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.iM(a)
if(q!=null)return q
if(typeof a=="function")return B.Y
t=Object.getPrototypeOf(a)
if(t==null)return B.E
if(t===Object.prototype)return B.E
if(typeof r=="function"){p=$.cX
if(p==null)p=$.cX=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.y,enumerable:false,writable:true,configurable:true})
return B.y}return B.y},
aP(a,b){if(a<0)throw A.c(A.aK("Length must be a non-negative integer: "+a))
return A.j(new Array(a),b.j("i<0>"))},
ef(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
fW(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.ef(s))break;++b}return b},
fX(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.a(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.ef(r))break}return b},
aj(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aQ.prototype
return J.bK.prototype}if(typeof a=="string")return J.a9.prototype
if(a==null)return J.aR.prototype
if(typeof a=="boolean")return J.bJ.prototype
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.W.prototype
if(typeof a=="symbol")return J.as.prototype
if(typeof a=="bigint")return J.ar.prototype
return a}if(a instanceof A.k)return a
return J.dd(a)},
dO(a){if(typeof a=="string")return J.a9.prototype
if(a==null)return a
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.W.prototype
if(typeof a=="symbol")return J.as.prototype
if(typeof a=="bigint")return J.ar.prototype
return a}if(a instanceof A.k)return a
return J.dd(a)},
dP(a){if(a==null)return a
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.W.prototype
if(typeof a=="symbol")return J.as.prototype
if(typeof a=="bigint")return J.ar.prototype
return a}if(a instanceof A.k)return a
return J.dd(a)},
iB(a){if(typeof a=="string")return J.a9.prototype
if(a==null)return a
if(!(a instanceof A.k))return J.aB.prototype
return a},
iC(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.W.prototype
if(typeof a=="symbol")return J.as.prototype
if(typeof a=="bigint")return J.ar.prototype
return a}if(a instanceof A.k)return a
return J.dd(a)},
an(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.aj(a).v(a,b)},
M(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.iK(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.dO(a).q(a,b)},
fA(a,b){return J.iB(a).aJ(a,b)},
fB(a){return J.iC(a).aK(a)},
fC(a,b){return J.dP(a).L(a,b)},
N(a){return J.aj(a).gn(a)},
fD(a){return J.dP(a).gaP(a)},
e1(a){return J.dP(a).gB(a)},
e2(a){return J.dO(a).gl(a)},
fE(a){return J.aj(a).gt(a)},
bv(a){return J.aj(a).h(a)},
bH:function bH(){},
bJ:function bJ(){},
aR:function aR(){},
aU:function aU(){},
a1:function a1(){},
c1:function c1(){},
aB:function aB(){},
W:function W(){},
ar:function ar(){},
as:function as(){},
i:function i(a){this.$ti=a},
bI:function bI(){},
cr:function cr(a){this.$ti=a},
ao:function ao(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aS:function aS(){},
aQ:function aQ(){},
bK:function bK(){},
a9:function a9(){}},A={dp:function dp(){},
ei(a){return new A.at("Field '"+a+"' has been assigned during initialization.")},
ej(a){return new A.at("Field '"+a+"' has not been initialized.")},
fY(a){return new A.at("Field '"+a+"' has already been initialized.")},
a2(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
dv(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
dR(a){var t,s
for(t=$.K.length,s=0;s<t;++s)if(a===$.K[s])return!0
return!1},
fU(){return new A.bb("No element")},
at:function at(a){this.a=a},
cH:function cH(){},
aO:function aO(){},
Z:function Z(){},
au:function au(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
C:function C(){},
b5:function b5(a,b){this.a=a
this.$ti=b},
fO(a,b,c){var t,s,r,q,p,o,n,m=A.z(a),l=A.av(new A.Y(a,m.j("Y<1>")),!0,b),k=l.length,j=0
for(;;){if(!(j<k)){t=!0
break}s=l[j]
if(typeof s!="string"||"__proto__"===s){t=!1
break}++j}if(t){r={}
for(q=0,j=0;j<l.length;l.length===k||(0,A.dk)(l),++j,q=p){s=l[j]
c.a(a.q(0,s))
p=q+1
r[s]=q}o=A.av(new A.aW(a,m.j("aW<2>")),!0,c)
n=new A.aN(r,o,b.j("@<0>").S(c).j("aN<1,2>"))
n.$keys=l
return n}return new A.aM(A.h1(a,b,c),b.j("@<0>").S(c).j("aM<1,2>"))},
fd(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
iK(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.J.b(a)},
o(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.bv(a)
return t},
c2(a){var t,s=$.eq
if(s==null)s=$.eq=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
hf(a,b){var t,s=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(s==null)return null
if(3>=s.length)return A.a(s,3)
t=s[3]
if(t!=null)return parseInt(a,10)
if(s[2]!=null)return parseInt(a,16)
return null},
c3(a){var t,s,r,q
if(a instanceof A.k)return A.J(A.bt(a),null)
t=J.aj(a)
if(t===B.X||t===B.Z||u.w.b(a)){s=B.z(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.J(A.bt(a),null)},
er(a){var t,s,r
if(a==null||typeof a=="number"||A.dK(a))return J.bv(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.a0)return a.h(0)
if(a instanceof A.af)return a.aI(!0)
t=$.fz()
for(s=0;s<1;++s){r=t[s].bI(a)
if(r!=null)return r}return"Instance of '"+A.c3(a)+"'"},
hd(){return Date.now()},
he(){var t,s
if($.cD!==0)return
$.cD=1000
if(typeof window=="undefined")return
t=window
if(t==null)return
if(!!t.dartUseDateNowForTicks)return
s=t.performance
if(s==null)return
if(typeof s.now!="function")return
$.cD=1e6
$.dt=new A.cC(s)},
x(a){var t
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.b.K(t,10)|55296)>>>0,t&1023|56320)}}throw A.c(A.b4(a,0,1114111,null,null))},
a(a,b){if(a==null)J.e2(a)
throw A.c(A.db(a,b))},
db(a,b){var t,s="index"
if(!A.f1(b))return new A.U(!0,b,s,null)
t=J.e2(a)
if(b<0||b>=t)return A.ee(b,t,a,s)
return new A.ay(null,null,!0,b,s,"Value not in range")},
dM(a){return new A.U(!0,a,null,null)},
c(a){return A.v(a,new Error())},
v(a,b){var t
if(a==null)a=new A.bc()
b.dartException=a
t=A.iT
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
iT(){return J.bv(this.dartException)},
aJ(a,b){throw A.v(a,b==null?new Error():b)},
q(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.aJ(A.i1(a,b,c),t)},
i1(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.be("'"+t+"': Cannot "+p+" "+m+l+o)},
dk(a){throw A.c(A.a6(a))},
a_(a){var t,s,r,q,p,o
a=A.iP(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.j([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.cL(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
cM(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
eA(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
dq(a,b){var t=b==null,s=t?null:b.method
return new A.bL(a,s,t?null:b.receiver)},
fe(a){if(a==null)return new A.cz(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.am(a,a.dartException)
return A.iv(a)},
am(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
iv(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.b.K(s,16)&8191)===10)switch(r){case 438:return A.am(a,A.dq(A.o(t)+" (Error "+r+")",null))
case 445:case 5007:A.o(t)
return A.am(a,new A.b3())}}if(a instanceof TypeError){q=$.fk()
p=$.fl()
o=$.fm()
n=$.fn()
m=$.fq()
l=$.fr()
k=$.fp()
$.fo()
j=$.ft()
i=$.fs()
h=q.I(t)
if(h!=null)return A.am(a,A.dq(A.a4(t),h))
else{h=p.I(t)
if(h!=null){h.method="call"
return A.am(a,A.dq(A.a4(t),h))}else if(o.I(t)!=null||n.I(t)!=null||m.I(t)!=null||l.I(t)!=null||k.I(t)!=null||n.I(t)!=null||j.I(t)!=null||i.I(t)!=null){A.a4(t)
return A.am(a,new A.b3())}}return A.am(a,new A.cb(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.ba()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.am(a,new A.U(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.ba()
return a},
f9(a){if(a==null)return J.N(a)
if(typeof a=="object")return A.c2(a)
return J.N(a)},
iz(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.i(0,a[t],a[s])}return b},
iA(a,b){var t,s=a.length
for(t=0;t<s;++t)b.k(0,a[t])
return b},
fN(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.c6().constructor.prototype):Object.create(new A.aq(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.e7(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.fJ(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.e7(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
fJ(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fH)}throw A.c("Error in functionType of tearoff")},
fK(a,b,c,d){var t=A.e6
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
e7(a,b,c,d){if(c)return A.fM(a,b,d)
return A.fK(b.length,d,a,b)},
fL(a,b,c,d){var t=A.e6,s=A.fI
switch(b?-1:a){case 0:throw A.c(new A.c4("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
fM(a,b,c){var t,s
if($.e4==null)$.e4=A.e3("interceptor")
if($.e5==null)$.e5=A.e3("receiver")
t=b.length
s=A.fL(t,c,a,b)
return s},
dN(a){return A.fN(a)},
fH(a,b){return A.br(v.typeUniverse,A.bt(a.a),b)},
e6(a){return a.a},
fI(a){return a.b},
e3(a){var t,s,r,q=new A.aq("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.c(A.aK("Field name "+a+" not found."))},
f7(a){return v.getIsolateTag(a)},
jv(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
iM(a){var t,s,r,q,p,o=A.a4($.f8.$1(a)),n=$.dc[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dh[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.dI($.f5.$2(a,o))
if(r!=null){n=$.dc[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dh[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.dj(t)
$.dc[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.dh[o]=t
return t}if(q==="-"){p=A.dj(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.fa(a,t)
if(q==="*")throw A.c(A.eB(o))
if(v.leafTags[o]===true){p=A.dj(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.fa(a,t)},
fa(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.dS(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
dj(a){return J.dS(a,!1,null,!!a.$iG)},
iO(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.dj(t)
else return J.dS(t,c,null,null)},
iG(){if(!0===$.dQ)return
$.dQ=!0
A.iH()},
iH(){var t,s,r,q,p,o,n,m
$.dc=Object.create(null)
$.dh=Object.create(null)
A.iF()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.fb.$1(p)
if(o!=null){n=A.iO(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
iF(){var t,s,r,q,p,o,n=B.Q()
n=A.aH(B.R,A.aH(B.S,A.aH(B.A,A.aH(B.A,A.aH(B.T,A.aH(B.U,A.aH(B.V(B.z),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.f8=new A.de(q)
$.f5=new A.df(p)
$.fb=new A.dg(o)},
aH(a,b){return a(b)||b},
ix(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
eg(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=function(g,h){try{return new RegExp(g,h)}catch(o){return o}}(a,t+s+r+q+f)
if(p instanceof RegExp)return p
throw A.c(A.V("Illegal RegExp pattern ("+String(p)+")",a,null))},
iQ(a,b,c){var t=a.indexOf(b,c)
return t>=0},
iP(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
p:function p(a,b){this.a=a
this.b=b},
aM:function aM(a,b){this.a=a
this.$ti=b},
aL:function aL(){},
aN:function aN(a,b,c){this.a=a
this.b=b
this.$ti=c},
cC:function cC(a){this.a=a},
b6:function b6(){},
cL:function cL(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
b3:function b3(){},
bL:function bL(a,b,c){this.a=a
this.b=b
this.c=c},
cb:function cb(a){this.a=a},
cz:function cz(a){this.a=a},
a0:function a0(){},
by:function by(){},
bz:function bz(){},
c8:function c8(){},
c6:function c6(){},
aq:function aq(a,b){this.a=a
this.b=b},
c4:function c4(a){this.a=a},
X:function X(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cu:function cu(a,b){this.a=a
this.b=b
this.c=null},
Y:function Y(a,b){this.a=a
this.$ti=b},
bO:function bO(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aW:function aW(a,b){this.a=a
this.$ti=b},
bP:function bP(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
de:function de(a){this.a=a},
df:function df(a){this.a=a},
dg:function dg(a){this.a=a},
af:function af(){},
aD:function aD(){},
aT:function aT(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
bh:function bh(a){this.b=a},
cc:function cc(a,b,c){this.a=a
this.b=b
this.c=c},
cO:function cO(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
c7:function c7(a,b){this.a=a
this.c=b},
cl:function cl(a,b,c){this.a=a
this.b=b
this.c=c},
d2:function d2(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
iR(a){throw A.v(A.ei(a),new Error())},
D(){throw A.v(A.ej(""),new Error())},
dT(){throw A.v(A.fY(""),new Error())},
iS(){throw A.v(A.ei(""),new Error())},
cV(a){var t=new A.cU(a)
return t.b=t},
cU:function cU(a){this.a=a
this.b=null},
i2(a){return a},
ha(a,b,c){var t=new DataView(a,b)
return t},
ep(a){return new Uint8Array(a)},
ag(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.db(b,a))},
aa:function aa(){},
b0:function b0(){},
d5:function d5(a){this.a=a},
bT:function bT(){},
ax:function ax(){},
aZ:function aZ(){},
b_:function b_(){},
bU:function bU(){},
bV:function bV(){},
bW:function bW(){},
bX:function bX(){},
bY:function bY(){},
bZ:function bZ(){},
c_:function c_(){},
b1:function b1(){},
b2:function b2(){},
bi:function bi(){},
bj:function bj(){},
bk:function bk(){},
bl:function bl(){},
du(a,b){var t=b.c
return t==null?b.c=A.bp(a,"ed",[b.x]):t},
eu(a){var t=a.w
if(t===6||t===7)return A.eu(a.x)
return t===11||t===12},
hj(a){return a.as},
cm(a){return A.d4(v.typeUniverse,a,!1)},
ah(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.ah(a0,t,a2,a3)
if(s===t)return a1
return A.eS(a0,s,!0)
case 7:t=a1.x
s=A.ah(a0,t,a2,a3)
if(s===t)return a1
return A.eR(a0,s,!0)
case 8:r=a1.y
q=A.aG(a0,r,a2,a3)
if(q===r)return a1
return A.bp(a0,a1.x,q)
case 9:p=a1.x
o=A.ah(a0,p,a2,a3)
n=a1.y
m=A.aG(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.dF(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.aG(a0,k,a2,a3)
if(j===k)return a1
return A.eT(a0,l,j)
case 11:i=a1.x
h=A.ah(a0,i,a2,a3)
g=a1.y
f=A.is(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.eQ(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.aG(a0,e,a2,a3)
p=a1.x
o=A.ah(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.dG(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.c(A.bx("Attempted to substitute unexpected RTI kind "+a))}},
aG(a,b,c,d){var t,s,r,q,p=b.length,o=A.d6(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.ah(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
it(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.d6(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.ah(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
is(a,b,c,d){var t,s=b.a,r=A.aG(a,s,c,d),q=b.b,p=A.aG(a,q,c,d),o=b.c,n=A.it(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.cf()
t.a=r
t.b=p
t.c=n
return t},
j(a,b){a[v.arrayRti]=b
return a},
f6(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.iE(t)
return a.$S()}return null},
iI(a,b){var t
if(A.eu(b))if(a instanceof A.a0){t=A.f6(a)
if(t!=null)return t}return A.bt(a)},
bt(a){if(a instanceof A.k)return A.z(a)
if(Array.isArray(a))return A.aF(a)
return A.dJ(J.aj(a))},
aF(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
z(a){var t=a.$ti
return t!=null?t:A.dJ(a)},
dJ(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.i9(a,t)},
i9(a,b){var t=a instanceof A.a0?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.hP(v.typeUniverse,t.name)
b.$ccache=s
return s},
iE(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.d4(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
iD(a){return A.ai(A.z(a))},
dL(a){var t
if(a instanceof A.af)return A.iy(a.$r,a.aA())
t=a instanceof A.a0?A.f6(a):null
if(t!=null)return t
if(u.k.b(a))return J.fE(a).a
if(Array.isArray(a))return A.aF(a)
return A.bt(a)},
ai(a){var t=a.r
return t==null?a.r=new A.d3(a):t},
iy(a,b){var t,s,r=b,q=r.length
if(q===0)return u.F
if(0>=q)return A.a(r,0)
t=A.br(v.typeUniverse,A.dL(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.a(r,s)
t=A.eU(v.typeUniverse,t,A.dL(r[s]))}return A.br(v.typeUniverse,t,a)},
R(a){return A.ai(A.d4(v.typeUniverse,a,!1))},
i8(a){var t=this
t.b=A.ir(t)
return t.b(a)},
ir(a){var t,s,r,q,p
if(a===u.K)return A.ig
if(A.ak(a))return A.ik
t=a.w
if(t===6)return A.i6
if(t===1)return A.f3
if(t===7)return A.ia
s=A.iq(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.ak)){a.f="$i"+r
if(r==="e")return A.id
if(a===u.m)return A.ic
return A.ij}}else if(t===10){q=A.ix(a.x,a.y)
p=q==null?A.f3:q
return p==null?A.dH(p):p}return A.i4},
iq(a){if(a.w===8){if(a===u.S)return A.f1
if(a===u.i||a===u.H)return A.ie
if(a===u.N)return A.ii
if(a===u.y)return A.dK}return null},
i7(a){var t=this,s=A.i3
if(A.ak(t))s=A.hZ
else if(t===u.K)s=A.dH
else if(A.aI(t)){s=A.i5
if(t===u.a3)s=A.hW
else if(t===u.dd)s=A.dI
else if(t===u.u)s=A.hT
else if(t===u.ae)s=A.eY
else if(t===u.I)s=A.hV
else if(t===u.z)s=A.hX}else if(t===u.S)s=A.T
else if(t===u.N)s=A.a4
else if(t===u.y)s=A.hS
else if(t===u.H)s=A.hY
else if(t===u.i)s=A.hU
else if(t===u.m)s=A.eX
t.a=s
return t.a(a)},
i4(a){var t=this
if(a==null)return A.aI(t)
return A.iL(v.typeUniverse,A.iI(a,t),t)},
i6(a){if(a==null)return!0
return this.x.b(a)},
ij(a){var t,s=this
if(a==null)return A.aI(s)
t=s.f
if(a instanceof A.k)return!!a[t]
return!!J.aj(a)[t]},
id(a){var t,s=this
if(a==null)return A.aI(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.k)return!!a[t]
return!!J.aj(a)[t]},
ic(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.k)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
f2(a){if(typeof a=="object"){if(a instanceof A.k)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
i3(a){var t=this
if(a==null){if(A.aI(t))return a}else if(t.b(a))return a
throw A.v(A.eZ(a,t),new Error())},
i5(a){var t=this
if(a==null||t.b(a))return a
throw A.v(A.eZ(a,t),new Error())},
eZ(a,b){return new A.bn("TypeError: "+A.eK(a,A.J(b,null)))},
eK(a,b){return A.bE(a)+": type '"+A.J(A.dL(a),null)+"' is not a subtype of type '"+b+"'"},
P(a,b){return new A.bn("TypeError: "+A.eK(a,b))},
ia(a){var t=this
return t.x.b(a)||A.du(v.typeUniverse,t).b(a)},
ig(a){return a!=null},
dH(a){if(a!=null)return a
throw A.v(A.P(a,"Object"),new Error())},
ik(a){return!0},
hZ(a){return a},
f3(a){return!1},
dK(a){return!0===a||!1===a},
hS(a){if(!0===a)return!0
if(!1===a)return!1
throw A.v(A.P(a,"bool"),new Error())},
hT(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.v(A.P(a,"bool?"),new Error())},
hU(a){if(typeof a=="number")return a
throw A.v(A.P(a,"double"),new Error())},
hV(a){if(typeof a=="number")return a
if(a==null)return a
throw A.v(A.P(a,"double?"),new Error())},
f1(a){return typeof a=="number"&&Math.floor(a)===a},
T(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.v(A.P(a,"int"),new Error())},
hW(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.v(A.P(a,"int?"),new Error())},
ie(a){return typeof a=="number"},
hY(a){if(typeof a=="number")return a
throw A.v(A.P(a,"num"),new Error())},
eY(a){if(typeof a=="number")return a
if(a==null)return a
throw A.v(A.P(a,"num?"),new Error())},
ii(a){return typeof a=="string"},
a4(a){if(typeof a=="string")return a
throw A.v(A.P(a,"String"),new Error())},
dI(a){if(typeof a=="string")return a
if(a==null)return a
throw A.v(A.P(a,"String?"),new Error())},
eX(a){if(A.f2(a))return a
throw A.v(A.P(a,"JSObject"),new Error())},
hX(a){if(a==null)return a
if(A.f2(a))return a
throw A.v(A.P(a,"JSObject?"),new Error())},
f4(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.J(a[r],b)
return t},
ip(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.f4(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.J(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
f_(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.j([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.k(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.a(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.J(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.J(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.J(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.J(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.J(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
J(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.J(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.J(a.x,b)+">"
if(m===8){q=A.iu(a.x)
p=a.y
return p.length>0?q+("<"+A.f4(p,b)+">"):q}if(m===10)return A.ip(a,b)
if(m===11)return A.f_(a,b,null)
if(m===12)return A.f_(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.a(b,o)
return b[o]}return"?"},
iu(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
hQ(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
hP(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.d4(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bq(a,5,"#")
r=A.d6(t)
for(q=0;q<t;++q)r[q]=s
p=A.bp(a,b,r)
o[b]=p
return p}else return n},
hO(a,b){return A.eV(a.tR,b)},
hN(a,b){return A.eV(a.eT,b)},
d4(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.eO(A.eM(a,null,b,!1))
s.set(b,t)
return t},
br(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.eO(A.eM(a,b,c,!0))
r.set(c,s)
return s},
eU(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.dF(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
a3(a,b){b.a=A.i7
b.b=A.i8
return b},
bq(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.Q(null,null)
t.w=b
t.as=c
s=A.a3(a,t)
a.eC.set(c,s)
return s},
eS(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.hL(a,b,s,c)
a.eC.set(s,t)
return t},
hL(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.ak(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.aI(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.Q(null,null)
r.w=6
r.x=b
r.as=c
return A.a3(a,r)},
eR(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.hJ(a,b,s,c)
a.eC.set(s,t)
return t},
hJ(a,b,c,d){var t,s
if(d){t=b.w
if(A.ak(b)||b===u.K)return b
else if(t===1)return A.bp(a,"ed",[b])
else if(b===u.P||b===u.T)return u.bc}s=new A.Q(null,null)
s.w=7
s.x=b
s.as=c
return A.a3(a,s)},
hM(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.Q(null,null)
t.w=13
t.x=b
t.as=r
s=A.a3(a,t)
a.eC.set(r,s)
return s},
bo(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
hI(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bp(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.bo(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.Q(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.a3(a,s)
a.eC.set(q,r)
return r},
dF(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.bo(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.Q(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.a3(a,p)
a.eC.set(r,o)
return o},
eT(a,b,c){var t,s,r="+"+(b+"("+A.bo(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.Q(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.a3(a,t)
a.eC.set(r,s)
return s},
eQ(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.bo(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.bo(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.hI(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.Q(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.a3(a,q)
a.eC.set(s,p)
return p},
dG(a,b,c,d){var t,s=b.as+("<"+A.bo(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.hK(a,b,c,s,d)
a.eC.set(s,t)
return t},
hK(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.d6(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.ah(a,b,s,0)
n=A.aG(a,c,s,0)
return A.dG(a,o,n,c!==n)}}m=new A.Q(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.a3(a,m)},
eM(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
eO(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.hD(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.eN(a,s,m,l,!1)
else if(r===46)s=A.eN(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.ae(a.u,a.e,l.pop()))
break
case 94:l.push(A.hM(a.u,l.pop()))
break
case 35:l.push(A.bq(a.u,5,"#"))
break
case 64:l.push(A.bq(a.u,2,"@"))
break
case 126:l.push(A.bq(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.hF(a,l)
break
case 38:A.hE(a,l)
break
case 63:q=a.u
l.push(A.eS(q,A.ae(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.eR(q,A.ae(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.hC(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.eP(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.hH(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.ae(a.u,a.e,n)},
hD(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
eN(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.hQ(t,p.x)[q]
if(o==null)A.aJ('No "'+q+'" in "'+A.hj(p)+'"')
d.push(A.br(t,p,o))}else d.push(q)
return n},
hF(a,b){var t,s=a.u,r=A.eL(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bp(s,q,r))
else{t=A.ae(s,a.e,q)
switch(t.w){case 11:b.push(A.dG(s,t,r,a.n))
break
default:b.push(A.dF(s,t,r))
break}}},
hC(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.eL(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.ae(q,a.e,p)
r=new A.cf()
r.a=t
r.b=o
r.c=n
b.push(A.eQ(q,s,r))
return
case-4:b.push(A.eT(q,b.pop(),t))
return
default:throw A.c(A.bx("Unexpected state under `()`: "+A.o(p)))}},
hE(a,b){var t=b.pop()
if(0===t){b.push(A.bq(a.u,1,"0&"))
return}if(1===t){b.push(A.bq(a.u,4,"1&"))
return}throw A.c(A.bx("Unexpected extended operation "+A.o(t)))},
eL(a,b){var t=b.splice(a.p)
A.eP(a.u,a.e,t)
a.p=b.pop()
return t},
ae(a,b,c){if(typeof c=="string")return A.bp(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.hG(a,b,c)}else return c},
eP(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.ae(a,b,c[t])},
hH(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.ae(a,b,c[t])},
hG(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.c(A.bx("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.c(A.bx("Bad index "+c+" for "+b.h(0)))},
iL(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.u(a,b,null,c,null)
s.set(c,t)}return t},
u(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.ak(d))return!0
t=b.w
if(t===4)return!0
if(A.ak(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.u(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.u(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.u(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.u(a,b.x,c,d,e))return!1
return A.u(a,A.du(a,b),c,d,e)}if(t===6)return A.u(a,q,c,d,e)&&A.u(a,b.x,c,d,e)
if(r===7){if(A.u(a,b,c,d.x,e))return!0
return A.u(a,b,c,A.du(a,d),e)}if(r===6)return A.u(a,b,c,q,e)||A.u(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.L)return!0
if(r===12){if(b===u.g)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.u(a,k,c,j,e)||!A.u(a,j,e,k,c))return!1}return A.f0(a,b.x,c,d.x,e)}if(r===11){if(b===u.g)return!0
if(q)return!1
return A.f0(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.ib(a,b,c,d,e)}if(p&&r===10)return A.ih(a,b,c,d,e)
return!1},
f0(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.u(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.u(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.u(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.u(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.u(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
ib(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.br(a,b,s[p])
return A.eW(a,q,null,c,d.y,e)}return A.eW(a,b.y,null,c,d.y,e)},
eW(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.u(a,b[t],d,e[t],f))return!1
return!0},
ih(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.u(a,s[t],c,r[t],e))return!1
return!0},
aI(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.ak(a))if(t!==6)s=t===7&&A.aI(a.x)
return s},
ak(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
eV(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
d6(a){return a>0?new Array(a):v.typeUniverse.sEA},
Q:function Q(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
cf:function cf(){this.c=this.b=this.a=null},
d3:function d3(a){this.a=a},
ce:function ce(){},
bn:function bn(a){this.a=a},
fZ(a,b){return new A.X(a.j("@<0>").S(b).j("X<1,2>"))},
h0(a,b,c){return b.j("@<0>").S(c).j("ek<1,2>").a(A.iz(a,new A.X(b.j("@<0>").S(c).j("X<1,2>"))))},
h_(a,b){return new A.X(a.j("@<0>").S(b).j("X<1,2>"))},
h2(a){return new A.ad(a.j("ad<0>"))},
h3(a,b){return b.j("el<0>").a(A.iA(a,new A.ad(b.j("ad<0>"))))},
dE(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
hB(a,b,c){var t=new A.aC(a,b,c.j("aC<0>"))
t.c=a.e
return t},
h1(a,b,c){var t=A.fZ(b,c)
a.J(0,new A.cv(t,b,c))
return t},
cw(a){var t,s
if(A.dR(a))return"{...}"
t=new A.aA("")
try{s={}
B.a.k($.K,a)
t.a+="{"
s.a=!0
a.J(0,new A.cx(s,t))
t.a+="}"}finally{if(0>=$.K.length)return A.a($.K,-1)
$.K.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
ad:function ad(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cj:function cj(a){this.a=a
this.b=null},
aC:function aC(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
cv:function cv(a,b,c){this.a=a
this.b=b
this.c=c},
m:function m(){},
I:function I(){},
cx:function cx(a,b){this.a=a
this.b=b},
bs:function bs(){},
aw:function aw(){},
bd:function bd(){},
az:function az(){},
bm:function bm(){},
aE:function aE(){},
io(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.fe(s)
r=A.V(String(t),null,null)
throw A.c(r)}r=A.d9(q)
return r},
d9(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.ch(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.d9(a[t])
return a},
hq(a,b,c,d,e,a0){var t,s,r,q,p,o,n,m,l,k,j="Invalid encoding before padding",i="Invalid character",h=B.b.K(a0,2),g=a0&3,f=$.fv()
for(t=a.length,s=f.length,r=d.$flags|0,q=b,p=0;q<c;++q){if(!(q<t))return A.a(a,q)
o=a.charCodeAt(q)
p|=o
n=o&127
if(!(n<s))return A.a(f,n)
m=f[n]
if(m>=0){h=(h<<6|m)&16777215
g=g+1&3
if(g===0){l=e+1
r&2&&A.q(d)
n=d.length
if(!(e<n))return A.a(d,e)
d[e]=h>>>16&255
e=l+1
if(!(l<n))return A.a(d,l)
d[l]=h>>>8&255
l=e+1
if(!(e<n))return A.a(d,e)
d[e]=h&255
e=l
h=0}continue}else if(m===-1&&g>1){if(p>127)break
if(g===3){if((h&3)!==0)throw A.c(A.V(j,a,q))
l=e+1
r&2&&A.q(d)
t=d.length
if(!(e<t))return A.a(d,e)
d[e]=h>>>10
if(!(l<t))return A.a(d,l)
d[l]=h>>>2}else{if((h&15)!==0)throw A.c(A.V(j,a,q))
r&2&&A.q(d)
if(!(e<d.length))return A.a(d,e)
d[e]=h>>>4}k=(3-g)*3
if(o===37)k+=2
return A.eC(a,q+1,c,-k-1)}throw A.c(A.V(i,a,q))}if(p>=0&&p<=127)return(h<<2|g)>>>0
for(q=b;q<c;++q){if(!(q<t))return A.a(a,q)
if(a.charCodeAt(q)>127)break}throw A.c(A.V(i,a,q))},
ho(a,b,c,d){var t=A.hp(a,b,c),s=(d&3)+(t-b),r=B.b.K(s,2)*3,q=s&3
if(q!==0&&t<c)r+=q-1
if(r>0)return new Uint8Array(r)
return $.fu()},
hp(a,b,c){var t,s=a.length,r=c,q=r,p=0
for(;;){if(!(q>b&&p<2))break
A:{--q
if(!(q>=0&&q<s))return A.a(a,q)
t=a.charCodeAt(q)
if(t===61){++p
r=q
break A}if((t|32)===100){if(q===b)break;--q
if(!(q>=0&&q<s))return A.a(a,q)
t=a.charCodeAt(q)}if(t===51){if(q===b)break;--q
if(!(q>=0&&q<s))return A.a(a,q)
t=a.charCodeAt(q)}if(t===37){++p
r=q
break A}break}}return r},
eC(a,b,c,d){var t,s,r
if(b===c)return d
t=-d-1
for(s=a.length;t>0;){if(!(b<s))return A.a(a,b)
r=a.charCodeAt(b)
if(t===3){if(r===61){t-=3;++b
break}if(r===37){--t;++b
if(b===c)break
if(!(b<s))return A.a(a,b)
r=a.charCodeAt(b)}else break}if((t>3?t-3:t)===2){if(r!==51)break;++b;--t
if(b===c)break
if(!(b<s))return A.a(a,b)
r=a.charCodeAt(b)}if((r|32)!==100)break;++b;--t
if(b===c)break}if(b!==c)throw A.c(A.V("Invalid padding character",a,b))
return-t-1},
eh(a,b,c){return new A.aV(a,b)},
i0(a){return a.bM()},
hz(a,b){return new A.cY(a,[],A.iw())},
hA(a,b,c){var t,s=new A.aA(""),r=A.hz(s,b)
r.a4(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
ch:function ch(a,b){this.a=a
this.b=b
this.c=null},
ci:function ci(a){this.a=a},
cn:function cn(){},
cP:function cP(){this.a=0},
bA:function bA(){},
bC:function bC(){},
aV:function aV(a,b){this.a=a
this.b=b},
bN:function bN(a,b){this.a=a
this.b=b},
bM:function bM(){},
ct:function ct(a){this.b=a},
cs:function cs(a){this.a=a},
cZ:function cZ(){},
d_:function d_(a,b){this.a=a
this.b=b},
cY:function cY(a,b,c){this.c=a
this.a=b
this.b=c},
hu(a,b){var t,s,r=$.B(),q=a.length,p=4-q%4
if(p===4)p=0
for(t=0,s=0;s<q;++s){t=t*10+a.charCodeAt(s)-48;++p
if(p===4){r=r.W(0,$.e_()).ak(0,A.ac(t))
t=0
p=0}}if(b)return r.E(0)
return r},
dC(a){if(48<=a&&a<=57)return a-48
return(a|32)-97+10},
hv(a,b,c){var t,s,r,q,p,o,n,m=a.length,l=m-b,k=B.q.bq(l/4),j=new Uint16Array(k),i=k-1,h=l-i*4
for(t=b,s=0,r=0;r<h;++r,t=q){q=t+1
if(!(t<m))return A.a(a,t)
p=A.dC(a.charCodeAt(t))
if(p>=16)return null
s=s*16+p}o=i-1
if(!(i>=0&&i<k))return A.a(j,i)
j[i]=s
for(;t<m;o=n){for(s=0,r=0;r<4;++r,t=q){q=t+1
if(!(t>=0&&t<m))return A.a(a,t)
p=A.dC(a.charCodeAt(t))
if(p>=16)return null
s=s*16+p}n=o-1
if(!(o>=0&&o<k))return A.a(j,o)
j[o]=s}if(k===1){if(0>=k)return A.a(j,0)
m=j[0]===0}else m=!1
if(m)return $.B()
m=A.y(k,j)
return new A.n(m===0?!1:c,j,m)},
hw(a,b,c){var t,s,r,q=$.B(),p=A.ac(b)
for(t=a.length,s=0;s<t;++s){r=A.dC(a.charCodeAt(s))
if(r>=b)return null
q=q.W(0,p).ak(0,A.ac(r))}if(c)return q.E(0)
return q},
hy(a,b){var t,s,r,q,p,o,n,m=null
if(a==="")return m
t=$.fx().bz(a)
if(t==null)return m
s=t.b
r=s.length
if(1>=r)return A.a(s,1)
q=s[1]==="-"
if(4>=r)return A.a(s,4)
p=s[4]
o=s[3]
if(5>=r)return A.a(s,5)
n=s[5]
if(b<2||b>36)throw A.c(A.b4(b,2,36,"radix",m))
if(b===10&&p!=null)return A.hu(p,q)
if(b===16)s=p!=null||n!=null
else s=!1
if(s){if(p==null){n.toString
s=n}else s=p
return A.hv(s,0,q)}s=p==null?n:p
if(s==null){o.toString
s=o}return A.hw(s,b,q)},
y(a,b){var t,s=b.length
for(;;){if(a>0){t=a-1
if(!(t<s))return A.a(b,t)
t=b[t]===0}else t=!1
if(!t)break;--a}return a},
dB(a,b,c,d){var t,s,r,q=new Uint16Array(d),p=c-b
for(t=a.length,s=0;s<p;++s){r=b+s
if(!(r>=0&&r<t))return A.a(a,r)
r=a[r]
if(!(s<d))return A.a(q,s)
q[s]=r}return q},
cQ(a){var t
if(a===0)return $.B()
if(a===1)return $.L()
if(a===2)return $.fy()
if(Math.abs(a)<4294967296)return A.ac(B.b.a3(a))
t=A.hr(a)
return t},
ac(a){var t,s,r,q,p=a<0
if(p){if(a===-9223372036854776e3){t=new Uint16Array(4)
t[3]=32768
s=A.y(4,t)
return new A.n(s!==0,t,s)}a=-a}if(a<65536){t=new Uint16Array(1)
t[0]=a
s=A.y(1,t)
return new A.n(s===0?!1:p,t,s)}if(a<=4294967295){t=new Uint16Array(2)
t[0]=a&65535
t[1]=B.b.K(a,16)
s=A.y(2,t)
return new A.n(s===0?!1:p,t,s)}s=B.b.m(B.b.gaL(a)-1,16)+1
t=new Uint16Array(s)
for(r=0;a!==0;r=q){q=r+1
if(!(r<s))return A.a(t,r)
t[r]=a&65535
a=B.b.m(a,65536)}s=A.y(s,t)
return new A.n(s===0?!1:p,t,s)},
hr(a){var t,s,r,q,p,o,n,m
if(isNaN(a)||a==1/0||a==-1/0)throw A.c(A.aK("Value must be finite: "+a))
t=a<0
if(t)a=-a
a=Math.floor(a)
if(a===0)return $.B()
s=$.fw()
for(r=s.$flags|0,q=0;q<8;++q){r&2&&A.q(s)
if(!(q<8))return A.a(s,q)
s[q]=0}r=J.fB(B.aU.gbp(s))
r.$flags&2&&A.q(r,13)
r.setFloat64(0,a,!0)
p=(s[7]<<4>>>0)+(s[6]>>>4)-1075
o=new Uint16Array(4)
o[0]=(s[1]<<8>>>0)+s[0]
o[1]=(s[3]<<8>>>0)+s[2]
o[2]=(s[5]<<8>>>0)+s[4]
o[3]=s[6]&15|16
n=new A.n(!1,o,4)
if(p<0)m=n.al(0,-p)
else m=p>0?n.F(0,p):n
if(t)return m.E(0)
return m},
dD(a,b,c,d){var t,s,r,q,p
if(b===0)return 0
if(c===0&&d===a)return b
for(t=b-1,s=a.length,r=d.$flags|0;t>=0;--t){q=t+c
if(!(t<s))return A.a(a,t)
p=a[t]
r&2&&A.q(d)
if(!(q>=0&&q<d.length))return A.a(d,q)
d[q]=p}for(t=c-1;t>=0;--t){r&2&&A.q(d)
if(!(t<d.length))return A.a(d,t)
d[t]=0}return b+c},
eI(a,b,c,d){var t,s,r,q,p,o,n,m=B.b.m(c,16),l=B.b.V(c,16),k=16-l,j=B.b.F(1,k)-1
for(t=b-1,s=a.length,r=d.$flags|0,q=0;t>=0;--t){if(!(t<s))return A.a(a,t)
p=a[t]
o=t+m+1
n=B.b.ae(p,k)
r&2&&A.q(d)
if(!(o>=0&&o<d.length))return A.a(d,o)
d[o]=(n|q)>>>0
q=B.b.F(p&j,l)}r&2&&A.q(d)
if(!(m>=0&&m<d.length))return A.a(d,m)
d[m]=q},
eD(a,b,c,d){var t,s,r,q=B.b.m(c,16)
if(B.b.V(c,16)===0)return A.dD(a,b,q,d)
t=b+q+1
A.eI(a,b,c,d)
for(s=d.$flags|0,r=q;--r,r>=0;){s&2&&A.q(d)
if(!(r<d.length))return A.a(d,r)
d[r]=0}s=t-1
if(!(s>=0&&s<d.length))return A.a(d,s)
if(d[s]===0)t=s
return t},
hx(a,b,c,d){var t,s,r,q,p,o,n=B.b.m(c,16),m=B.b.V(c,16),l=16-m,k=B.b.F(1,m)-1,j=a.length
if(!(n>=0&&n<j))return A.a(a,n)
t=B.b.ae(a[n],m)
s=b-n-1
for(r=d.$flags|0,q=0;q<s;++q){p=q+n+1
if(!(p<j))return A.a(a,p)
o=a[p]
p=B.b.F(o&k,l)
r&2&&A.q(d)
if(!(q<d.length))return A.a(d,q)
d[q]=(p|t)>>>0
t=B.b.ae(o,m)}r&2&&A.q(d)
if(!(s>=0&&s<d.length))return A.a(d,s)
d[s]=t},
cR(a,b,c,d){var t,s,r,q,p=b-d
if(p===0)for(t=b-1,s=a.length,r=c.length;t>=0;--t){if(!(t<s))return A.a(a,t)
q=a[t]
if(!(t<r))return A.a(c,t)
p=q-c[t]
if(p!==0)return p}return p},
hs(a,b,c,d,e){var t,s,r,q,p,o
for(t=a.length,s=c.length,r=e.$flags|0,q=0,p=0;p<d;++p){if(!(p<t))return A.a(a,p)
o=a[p]
if(!(p<s))return A.a(c,p)
q+=o+c[p]
r&2&&A.q(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=q>>>16}for(p=d;p<b;++p){if(!(p>=0&&p<t))return A.a(a,p)
q+=a[p]
r&2&&A.q(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=q>>>16}r&2&&A.q(e)
if(!(b>=0&&b<e.length))return A.a(e,b)
e[b]=q},
cd(a,b,c,d,e){var t,s,r,q,p,o
for(t=a.length,s=c.length,r=e.$flags|0,q=0,p=0;p<d;++p){if(!(p<t))return A.a(a,p)
o=a[p]
if(!(p<s))return A.a(c,p)
q+=o-c[p]
r&2&&A.q(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=0-(B.b.K(q,16)&1)}for(p=d;p<b;++p){if(!(p>=0&&p<t))return A.a(a,p)
q+=a[p]
r&2&&A.q(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=0-(B.b.K(q,16)&1)}},
eJ(a,b,c,d,e,f){var t,s,r,q,p,o,n,m,l
if(a===0)return
for(t=b.length,s=d.length,r=d.$flags|0,q=0;--f,f>=0;e=m,c=p){p=c+1
if(!(c<t))return A.a(b,c)
o=b[c]
if(!(e>=0&&e<s))return A.a(d,e)
n=a*o+d[e]+q
m=e+1
r&2&&A.q(d)
d[e]=n&65535
q=B.b.m(n,65536)}for(;q!==0;e=m){if(!(e>=0&&e<s))return A.a(d,e)
l=d[e]+q
m=e+1
r&2&&A.q(d)
d[e]=l&65535
q=B.b.m(l,65536)}},
ht(a,b,c){var t,s,r,q=b.length
if(!(c>=0&&c<q))return A.a(b,c)
t=b[c]
if(t===a)return 65535
s=c-1
if(!(s>=0&&s<q))return A.a(b,s)
r=B.b.Z((t<<16|b[s])>>>0,a)
if(r>65535)return 65535
return r},
iJ(a){var t=A.hf(a,null)
if(t!=null)return t
throw A.c(A.V(a,null,null))},
H(a,b,c){var t,s,r
if(a>4294967295)A.aJ(A.b4(a,0,4294967295,"length",null))
t=A.j(new Array(a),c.j("i<0>"))
t.$flags=1
s=t
if(a!==0&&b!=null)for(t=s.length,r=0;r<t;++r)s[r]=b
return s},
av(a,b,c){var t,s=A.j([],c.j("i<0>"))
for(t=J.e1(a);t.p();)B.a.k(s,c.a(t.gu()))
if(b)return s
s.$flags=1
return s},
dr(a,b){var t=A.av(a,!1,b)
t.$flags=3
return t},
et(a,b){return new A.aT(a,A.eg(a,!1,b,!1,!1,""))},
ey(a,b,c){var t=J.e1(b)
if(!t.p())return a
if(c.length===0){do a+=A.o(t.gu())
while(t.p())}else{a+=A.o(t.gu())
while(t.p())a=a+c+A.o(t.gu())}return a},
e8(a,b){return new A.bD(a+1000*b)},
bE(a){if(typeof a=="number"||A.dK(a)||a==null)return J.bv(a)
if(typeof a=="string")return JSON.stringify(a)
return A.er(a)},
bx(a){return new A.bw(a)},
aK(a){return new A.U(!1,null,null,a)},
fF(a,b,c){return new A.U(!0,a,b,c)},
hg(a){var t=null
return new A.ay(t,t,!1,t,t,a)},
b4(a,b,c,d,e){return new A.ay(b,c,!0,a,d,"Invalid value")},
es(a,b,c){if(0>a||a>c)throw A.c(A.b4(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.b4(b,a,c,"end",null))
return b}return c},
hh(a,b){if(a<0)throw A.c(A.b4(a,0,null,b,null))
return a},
ee(a,b,c,d){return new A.bF(b,!0,a,d,"Index out of range")},
cN(a){return new A.be(a)},
eB(a){return new A.ca(a)},
ex(a){return new A.bb(a)},
a6(a){return new A.bB(a)},
V(a,b,c){return new A.cq(a,b,c)},
fV(a,b,c){var t,s
if(A.dR(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.j([],u.s)
B.a.k($.K,a)
try{A.il(a,t)}finally{if(0>=$.K.length)return A.a($.K,-1)
$.K.pop()}s=A.ey(b,u.U.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
dn(a,b,c){var t,s
if(A.dR(a))return b+"..."+c
t=new A.aA(b)
B.a.k($.K,a)
try{s=t
s.a=A.ey(s.a,a,", ")}finally{if(0>=$.K.length)return A.a($.K,-1)
$.K.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
il(a,b){var t,s,r,q,p,o,n,m=a.gB(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.p())return
t=A.o(m.gu())
B.a.k(b,t)
l+=t.length+2;++k}if(!m.p()){if(k<=5)return
if(0>=b.length)return A.a(b,-1)
s=b.pop()
if(0>=b.length)return A.a(b,-1)
r=b.pop()}else{q=m.gu();++k
if(!m.p()){if(k<=4){B.a.k(b,A.o(q))
return}s=A.o(q)
if(0>=b.length)return A.a(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gu();++k
for(;m.p();q=p,p=o){o=m.gu();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2;--k}B.a.k(b,"...")
return}}r=A.o(q)
s=A.o(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.k(b,n)
B.a.k(b,r)
B.a.k(b,s)},
ds(a,b,c,d){var t
if(B.l===c){t=J.N(a)
b=J.N(b)
return A.dv(A.a2(A.a2($.dl(),t),b))}if(B.l===d){t=J.N(a)
b=J.N(b)
c=J.N(c)
return A.dv(A.a2(A.a2(A.a2($.dl(),t),b),c))}t=J.N(a)
b=J.N(b)
c=J.N(c)
d=J.N(d)
d=A.dv(A.a2(A.a2(A.a2(A.a2($.dl(),t),b),c),d))
return d},
n:function n(a,b,c){this.a=a
this.b=b
this.c=c},
cS:function cS(){},
cT:function cT(){},
bD:function bD(a){this.a=a},
cW:function cW(){},
h:function h(){},
bw:function bw(a){this.a=a},
bc:function bc(){},
U:function U(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ay:function ay(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bF:function bF(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
be:function be(a){this.a=a},
ca:function ca(a){this.a=a},
bb:function bb(a){this.a=a},
bB:function bB(a){this.a=a},
c0:function c0(){},
ba:function ba(){},
cq:function cq(a,b,c){this.a=a
this.b=b
this.c=c},
bG:function bG(){},
d:function d(){},
ab:function ab(){},
k:function k(){},
cI:function cI(){this.b=this.a=0},
aA:function aA(a){this.a=a},
d0:function d0(){this.b=this.a=0},
fG(){var t,s,r=J.aP(8,u.l)
for(t=u.aD,s=0;s<8;++s)r[s]=A.H(8,null,t)
t=u.t
t=new A.co(r,B.c,A.j([],u.G),$.B(),A.j([],u.R),A.j([],t),A.j([null,null],u.B),A.j([0,0],t))
t.aV()
return t},
co:function co(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.d=_.c=!1
_.e=c
_.f=d
_.r=e
_.w=f
_.x=0
_.y=g
_.z=0
_.Q=h
_.as=0},
cg:function cg(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cp(){return new A.a7(A.dr(B.o,u.S),$.bu(),192,20,23,7,16,1)},
a7:function a7(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.at=$},
A:function A(a,b,c){this.a=a
this.b=b
this.c=c},
bR(a,b){var t,s,r,q,p=A.j([],u._),o=a.b,n=A.aY(a,o)
for(t=a.a,s=0;s<8;++s)for(r=0;r<8;++r){q=t[s][r]
if(q==null||q.b!==o)continue
A.h4(a,new A.t(s,r),q,n,b,p)}return p},
en(a,b,c){var t,s,r,q,p,o,n,m,l,k=b.a,j=b.b
for(t=0;t<8;++t){s=B.t[t]
if(A.aX(a,k+s.a,j+s.b,c,B.d))return!0}for(t=0;t<8;++t){s=B.u[t]
if(A.aX(a,k+s.a,j+s.b,c,B.k))return!0}for(t=0;t<4;++t){s=B.x[t]
if(A.aX(a,k+s.a,j+s.b,c,B.p))return!0}for(t=0;t<4;++t){s=B.w[t]
if(A.aX(a,k+s.a,j+s.b,c,B.j))return!0}r=c===B.c?j+1:j-1
if(A.aX(a,k-1,r,c,B.h)||A.aX(a,k+1,r,c,B.h))return!0
for(s=a.a,t=0;t<4;++t){q=B.v[t]
p=q.a
o=q.b
n=k+p
m=j+o
for(;;){if(!(n>=0&&n<8&&m>=0&&m<8))break
if(!(n>=0&&n<8))return A.a(s,n)
q=s[n]
if(!(m>=0&&m<8))return A.a(q,m)
l=q[m]
if(l!=null){if(l.b===c&&l.a===B.i)return!0
break}n+=p
m+=o}}return!1},
aX(a,b,c,d,e){var t,s
if(b<0||b>=8||c<0||c>=8)return!1
t=a.a
if(!(b>=0&&b<8))return A.a(t,b)
t=t[b]
if(!(c>=0&&c<8))return A.a(t,c)
s=t[c]
return s!=null&&s.b===d&&s.a===e},
aY(a,b){var t,s=a.y,r=b.a
if(!(r<2))return A.a(s,r)
t=s[r]
if(t==null)return!1
return A.en(a,t,b===B.c?B.e:B.c)},
h4(a,b,c,d,e,f){var t,s,r,q,p,o,n,m,l,k,j,i=f.length
A.h5(a,b,c,f)
t=c.b
s=a.y
r=t.a
if(!(r<2))return A.a(s,r)
q=s[r]
p=d||c.a===B.d||q==null||A.h6(a,b,q)
if(!p&&!e)return
for(s=a.a,o=i,n=o;o<f.length;++o){m=f[o]
if(e){r=m.b
l=r.a
if(!(l>=0&&l<8))return A.a(s,l)
l=s[l]
r=r.b
if(!(r>=0&&r<8))return A.a(l,r)
r=l[r]==null}else r=!1
if(r)continue
if(p){a.X(m)
k=A.aY(a,t)
a.Y()
if(k)continue}j=n+1
if(!(n<f.length))return A.a(f,n)
f[n]=m
n=j}B.a.sl(f,n)},
h6(a,b,c){if(b.a!==c.a&&b.b!==c.b)return!1
return A.h7(a,b,c)},
h5(a,b,c,d){switch(c.a.a){case 0:A.bS(a,b,c,B.t,d)
if(!(c.b===B.c?a.c:a.d))A.bS(a,b,c,B.u,d)
break
case 1:A.bS(a,b,c,B.x,d)
break
case 2:A.bS(a,b,c,B.w,d)
break
case 3:A.bS(a,b,c,B.u,d)
break
case 4:A.h9(a,b,c,B.v,d)
break
case 5:A.h8(a,b,c,d)
break}},
bS(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k
for(t=d.length,s=a.a,r=b.a,q=b.b,p=c.b,o=0;o<t;++o){n=d[o]
m=r+n.a
l=q+n.b
if(m<0||m>=8||l<0||l>=8)continue
if(!(m>=0&&m<8))return A.a(s,m)
n=s[m]
if(!(l>=0&&l<8))return A.a(n,l)
k=n[l]
if(k==null||k.b!==p)B.a.k(e,new A.A(b,new A.t(m,l),null))}},
h9(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
for(t=a.a,s=b.a,r=b.b,q=c.b,p=0;p<4;++p){o=d[p]
n=o.a
m=o.b
l=s+n
k=r+m
for(;;){if(!(l>=0&&l<8&&k>=0&&k<8))break
if(!(l>=0&&l<8))return A.a(t,l)
o=t[l]
if(!(k>=0&&k<8))return A.a(o,k)
j=o[k]
if(j==null)B.a.k(e,new A.A(b,new A.t(l,k),null))
else{if(j.b!==q)B.a.k(e,new A.A(b,new A.t(l,k),null))
break}l+=n
k+=m}}},
h8(a,b,c,d){var t,s,r,q,p,o,n,m=c.b,l=m===B.c,k=l?-1:1,j=l?0:7,i=b.b+k
if(i>=0&&i<8){l=b.a
t=a.a
if(!(l>=0&&l<8))return A.a(t,l)
t=t[l]
if(!(i>=0&&i<8))return A.a(t,i)
if(t[i]==null)A.em(d,b,new A.t(l,i),m,j)}for(l=a.a,t=b.a,s=i>=0,r=i>=8,q=0;q<2;++q){p=t+B.aE[q]
if(p<0||p>=8||!s||r)continue
if(!(p>=0&&p<8))return A.a(l,p)
o=l[p]
if(!(i>=0&&i<8))return A.a(o,i)
n=o[i]
if(n!=null&&n.b!==m)A.em(d,b,new A.t(p,i),m,j)}},
em(a,b,c,d,e){var t,s,r
if(c.b!==e){B.a.k(a,new A.A(b,c,null))
return}t=c.a
if(d===B.c){if(!(t>=0&&t<8))return A.a(B.n,t)
s=B.n[t]}else{if(!(t>=0&&t<8))return A.a(B.m,t)
s=B.m[t]}r=s===B.d?null:s
if(r==null)return
B.a.k(a,new A.A(b,c,r))},
eo(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j,i={}
i.a=null
i.b=1073741824
t=new A.cy(i,d,a,c,e)
s=b.a
r=b.b
for(q=0;q<8;++q){p=B.t[q]
t.$3(s+p.a,r+p.b,B.d)}for(q=0;q<8;++q){p=B.u[q]
t.$3(s+p.a,r+p.b,B.k)}for(q=0;q<4;++q){p=B.x[q]
t.$3(s+p.a,r+p.b,B.p)}for(q=0;q<4;++q){p=B.w[q]
t.$3(s+p.a,r+p.b,B.j)}o=c===B.c?r+1:r-1
t.$3(s-1,o,B.h)
t.$3(s+1,o,B.h)
for(p=a.a,q=0;q<4;++q){n=B.v[q]
m=n.a
l=n.b
k=s+m
j=r+l
for(;;){if(!(k>=0&&k<8&&j>=0&&j<8))break
if(!d.a1(0,new A.t(k,j))){if(!(k>=0&&k<8))return A.a(p,k)
n=p[k]
if(!(j>=0&&j<8))return A.a(n,j)
n=n[j]!=null}else n=!1
if(n){t.$3(k,j,B.i)
break}k+=m
j+=l}}return i.a},
h7(a,b,c){var t=c.a,s=b.a,r=B.b.gam(t-s),q=c.b,p=b.b,o=B.b.gam(q-p),n=s+r,m=p+o
s=a.a
for(;;){if(!(n!==t||m!==q))break
if(!(n>=0&&n<8))return A.a(s,n)
p=s[n]
if(!(m>=0&&m<8))return A.a(p,m)
if(p[m]!=null)return!1
n+=r
m+=o}return!0},
cy:function cy(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
hb(a){var t,s,r,q,p,o,n,m,l,k,j=u.Y,i=u.O,h=A.h_(j,i)
for(t=a.split("\n"),s=t.length,r=0;r<s;++r){q=B.f.bH(t[r])
if(q.length===0||B.f.aX(q,"#"))continue
p=B.f.aW(q,A.et("\\s+",!0))
o=p.length
if(o!==2)continue
if(0>=o)return A.a(p,0)
o=A.hy(p[0],16)
if(o==null)n=null
else{m=$.L()
l=m.F(0,63)
n=o.R(0,l.N(0,m)).N(0,o.R(0,l))}if(1>=p.length)return A.a(p,1)
k=A.hc(p[1])
if(n==null||k==null)continue
h.i(0,n,k)}return new A.cA(A.fO(h,j,i))},
hc(a){var t,s,r,q,p,o,n=null,m=a.length
if(m<4||m>5)return n
t=null
s=null
try{t=A.ew(B.f.G(a,0,2))
s=A.ew(B.f.G(a,2,4))}catch(r){return n}q=n
if(m===5){for(p=0;p<6;++p){o=B.r[p]
if(4>=m)return A.a(a,4)
if(o.c===a[4].toUpperCase())q=o}if(q==null)return n}return new A.A(t,s,q)},
cA:function cA(a){this.a=a},
b9:function b9(a,b){this.a=a
this.b=b},
E:function E(a,b,c){this.c=a
this.a=b
this.b=c},
S:function S(a,b){this.a=a
this.b=b},
ev(a,b,c){return new A.cF(a,b,c)},
hk(a){var t,s
u.a.a(a)
if(a===B.d)t=3e4
else{t=$.F
t=(t==null?$.F=A.cp():t).a
s=a.a
if(!(s<t.length))return A.a(t,s)
s=t[s]
t=s}return t},
cG(a,b,c){var t,s,r,q,p,o,n
for(t=c+1,s=a.length,r=b.length,q=c;t<s;++t){if(!(t<r))return A.a(b,t)
p=b[t]
if(!(q>=0&&q<r))return A.a(b,q)
if(p>b[q])q=t}if(q===c)return
if(!(c<s))return A.a(a,c)
o=a[c]
if(!(q>=0&&q<s))return A.a(a,q)
a[c]=a[q]
a[q]=o
if(!(c<r))return A.a(b,c)
n=b[c]
if(!(q<r))return A.a(b,q)
b[c]=b[q]
b[q]=n},
c5:function c5(a){this.Q=a},
b8:function b8(a,b,c){this.a=a
this.b=b
this.c=c},
cF:function cF(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.r=_.f=$
_.w=!1
_.x=0
_.y=$
_.z=null
_.Q=$
_.at=_.as=null
_.ax=!1},
ck:function ck(a,b){this.a=a
this.b=b},
ew(a){var t=a.length
if(t!==2)throw A.c(A.fF(a,"algebraic","must be length 2"))
if(0>=t)return A.a(a,0)
if(1>=t)return A.a(a,1)
return new A.t(a.charCodeAt(0)-97,A.iJ(a[1])-1)},
t:function t(a,b){this.a=a
this.b=b},
ez(a,b,c,d,e,f){return((((a*64+b)*64+c)*2+d)*2+e)*2+f},
cJ:function cJ(a){this.a=a},
b7:function b7(a,b){this.a=a
this.b=b},
c9:function c9(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
cK:function cK(a,b){this.a=a
this.b=b},
bf(a,b,c,d){var t=a.a*2+b.a,s=c*8+d,r=$.a5().a
r===$&&A.D()
if(!(t<12))return A.a(r,t)
r=r[t]
if(!(s>=0&&s<64))return A.a(r,s)
return r[s]},
hR(){var t=new A.d7()
t.b0()
return t},
d7:function d7(){this.c=this.b=this.a=$},
d8:function d8(a){this.a=a},
iN(){var t,s,r={}
r.a=null
t=v.G.self
r=new A.di(r)
if(typeof r=="function")A.aJ(A.aK("Attempting to rewrap a JS function."))
s=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.i_,r)
s[$.dU()]=r
t.onmessage=s},
di:function di(a){this.a=a},
i_(a,b,c){u.Z.a(a)
if(A.T(c)>=1)return a.$1(b)
return a.$0()},
fP(b1,b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=$.F
if(b0==null){b0=A.cp()
$.F=b0
t=b0}else t=b0
s=t.at
if(s===$){r=t.bc()
t.at!==$&&A.iS()
t.at=r
s=r}q=$.fi()
p=$.fg()
o=$.fj()
n=$.fh()
for(b0=s.length,m=b1.a,l=0,k=0,j=0,i=0,h=0,g=0,f=0,e=0;e<8;++e){B.a.i(q,e,0)
B.a.i(p,e,0)
B.a.i(o,e,-1)
B.a.i(n,e,8)
for(d=e*8,c=0;c<8;++c){b=m[e][c]
if(b==null)continue
a=b.a.a
a0=b.b
a1=(a*2+a0.a)*64+d+c
if(!(a1<b0))return A.a(s,a1)
a2=s[a1]
if(a0===B.c){l+=a2
switch(a){case 5:B.a.i(q,e,q[e]+1)
if(c>o[e])B.a.i(o,e,c)
a3=k+1
B.a.i($.dX(),k,d+c)
k=a3
break
case 4:a4=i+1
B.a.i($.dY(),i,e)
i=a4
break
case 0:break
default:++g}}else{l-=a2
switch(a){case 5:B.a.i(p,e,p[e]+1)
if(c<n[e])B.a.i(n,e,c)
a5=j+1
B.a.i($.dV(),j,d+c)
j=a5
break
case 4:a6=h+1
B.a.i($.dW(),h,e)
h=a6
break
case 0:break
default:++f}}}}b0=A.eb(q,t)
m=A.eb(p,t)
d=A.ea($.dX(),k,B.c,n,t)
a=A.ea($.dV(),j,B.e,o,t)
a0=A.ec($.dY(),i,q,p,t)
a1=A.ec($.dW(),h,p,q,t)
a7=A.e9(b1,B.c,t)
a8=A.e9(b1,B.e,t)
l=l-b0+m+d-a+a0-a1-a7+a8
b0=b1.c
if(!b0)l+=t.c+B.b.Z(a7,t.w)
b0=b1.d
if(!b0)l-=t.c+B.b.Z(a8,t.w)
a9=h+j
b0=i+k===0
if(b0&&a9===0&&g+f<=1)l=B.b.m(l*0,100)
else{if(!(l>0&&b0))b0=l<0&&a9===0
else b0=!0
if(b0)l=B.b.m(l*50,100)}return l},
ea(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f
if(b===0)return 0
t=e.a
s=t.length
if(4>=s)return A.a(t,4)
r=t[4]
for(q=c===B.c,p=0,o=0;o<b;++o){if(!(o<16))return A.a(a,o)
n=a[o]
m=n>>>3
l=n&7
k=m-1
n=m+1
j=!0
for(;;){if(!(k<=n&&j))break
A:{if(k<0||k>7)break A
if(!(k>=0&&k<8))return A.a(d,k)
i=d[k]
if(q?i<l:i>l)j=!1}++k}if(!j)continue
h=q?l:7-l
if(q){if(!(m<8))return A.a(B.n,m)
g=B.n[m]}else{if(!(m<8))return A.a(B.m,m)
g=B.m[m]}if(g===B.d)f=25
else{n=g.a
if(!(n<s))return A.a(t,n)
f=B.b.Z(t[n]*100,r)}if(!(h<7))return A.a(B.C,h)
p+=B.b.m(B.C[h]*f,100)}return p},
ec(a,b,c,d,e){var t,s,r
for(t=0,s=0;s<b;++s){if(!(s<16))return A.a(a,s)
r=a[s]
if(!(r<8))return A.a(c,r)
if(c[r]!==0)continue
t+=d[r]===0?30:15}return t},
eb(a,b){var t,s,r,q,p,o,n
for(t=b.d,s=b.e,r=0,q=0;q<8;++q){p=a[q]
if(p===0)continue
if(p>1)r+=t*(p-1)
o=q>0&&a[q-1]>0
n=q<7&&a[q+1]>0
if(!o&&!n)r+=s*p}return r},
e9(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i=a.y,h=b.a
if(!(h<2))return A.a(i,h)
t=i[h]
if(t==null)return 0
for(i=a.a,h=b===B.c,s=t.a,r=t.b,q=0,p=0,o=0;o<8;++o){n=B.t[o]
m=s+n.a
l=r+n.b
if(m<0||m>=8||l<0||l>=8)continue
n=h?B.e:B.c
if(A.en(a,new A.t(m,l),n))++q
if(!(m>=0&&m<8))return A.a(i,m)
n=i[m]
if(!(l>=0&&l<8))return A.a(n,l)
k=n[l]
if(k!=null&&k.b===b&&k.a===B.h)++p}j=c.f*q*q-c.r*p
return j<0?0:j}},B={}
var w=[A,J,B]
var $={}
A.dp.prototype={}
J.bH.prototype={
v(a,b){return a===b},
gn(a){return A.c2(a)},
h(a){return"Instance of '"+A.c3(a)+"'"},
gt(a){return A.ai(A.dJ(this))}}
J.bJ.prototype={
h(a){return String(a)},
gn(a){return a?519018:218159},
gt(a){return A.ai(u.y)},
$if:1,
$ida:1}
J.aR.prototype={
v(a,b){return null==b},
h(a){return"null"},
gn(a){return 0},
$if:1}
J.aU.prototype={$ir:1}
J.a1.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.c1.prototype={}
J.aB.prototype={}
J.W.prototype={
h(a){var t=a[$.ff()]
if(t==null)t=a[$.dU()]
if(t==null)return this.aZ(a)
return"JavaScript function for "+J.bv(t)},
$ia8:1}
J.ar.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.as.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.i.prototype={
k(a,b){A.aF(a).c.a(b)
a.$flags&1&&A.q(a,29)
a.push(b)},
af(a){a.$flags&1&&A.q(a,"clear","clear")
a.length=0},
L(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
gby(a){if(a.length>0)return a[0]
throw A.c(A.fU())},
a1(a,b){var t
for(t=0;t<a.length;++t)if(J.an(a[t],b))return!0
return!1},
gaP(a){return a.length!==0},
h(a){return A.dn(a,"[","]")},
gB(a){return new J.ao(a,a.length,A.aF(a).j("ao<1>"))},
gn(a){return A.c2(a)},
gl(a){return a.length},
sl(a,b){a.$flags&1&&A.q(a,"set length","change the length of")
if(b>a.length)A.aF(a).c.a(null)
a.length=b},
q(a,b){if(!(b>=0&&b<a.length))throw A.c(A.db(a,b))
return a[b]},
i(a,b,c){A.aF(a).c.a(c)
a.$flags&2&&A.q(a)
if(!(b>=0&&b<a.length))throw A.c(A.db(a,b))
a[b]=c},
$id:1,
$ie:1}
J.bI.prototype={
bI(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.c3(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.cr.prototype={}
J.ao.prototype={
gu(){var t=this.d
return t==null?this.$ti.c.a(t):t},
p(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.dk(r)
throw A.c(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0}}
J.aS.prototype={
P(a,b){var t
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=B.b.gai(b)
if(this.gai(a)===t)return 0
if(this.gai(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gai(a){return a===0?1/a<0:a<0},
a3(a){var t
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){t=a<0?Math.ceil(a):Math.floor(a)
return t+0}throw A.c(A.cN(""+a+".toInt()"))},
bq(a){var t,s
if(a>=0){if(a<=2147483647){t=a|0
return a===t?t:t+1}}else if(a>=-2147483648)return a|0
s=Math.ceil(a)
if(isFinite(s))return s
throw A.c(A.cN(""+a+".ceil()"))},
bA(a){var t,s
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){t=a|0
return a===t?t:t-1}s=Math.floor(a)
if(isFinite(s))return s
throw A.c(A.cN(""+a+".floor()"))},
aM(a,b,c){if(B.b.P(b,c)>0)throw A.c(A.dM(b))
if(this.P(a,b)<0)return b
if(this.P(a,c)>0)return c
return a},
h(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gn(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
V(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
Z(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.aH(a,b)},
m(a,b){return(a|0)===a?a/b|0:this.aH(a,b)},
aH(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.c(A.cN("Result of truncating division is "+A.o(t)+": "+A.o(a)+" ~/ "+b))},
F(a,b){if(b<0)throw A.c(A.dM(b))
return b>31?0:a<<b>>>0},
K(a,b){var t
if(a>0)t=this.aG(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
ae(a,b){if(0>b)throw A.c(A.dM(b))
return this.aG(a,b)},
aG(a,b){return b>31?0:a>>>b},
gt(a){return A.ai(u.H)},
$il:1,
$ial:1}
J.aQ.prototype={
gam(a){var t
if(a>0)t=1
else t=a<0?-1:a
return t},
gaL(a){var t,s=a<0?-a-1:a,r=s
for(t=32;r>=4294967296;){r=this.m(r,4294967296)
t+=32}return t-Math.clz32(r)},
gt(a){return A.ai(u.S)},
$if:1,
$ib:1}
J.bK.prototype={
gt(a){return A.ai(u.i)},
$if:1}
J.a9.prototype={
aJ(a,b){return new A.cl(b,a,0)},
aW(a,b){var t
if(typeof b=="string")return A.j(a.split(b),u.s)
else{if(b instanceof A.aT){t=b.e
t=!(t==null?b.e=b.b4():t)}else t=!1
if(t)return A.j(a.split(b.b),u.s)
else return this.b6(a,b)}},
b6(a,b){var t,s,r,q,p,o,n=A.j([],u.s)
for(t=J.fA(b,a),t=t.gB(t),s=0,r=1;t.p();){q=t.gu()
p=q.gan()
o=q.gag()
r=o-p
if(r===0&&s===p)continue
B.a.k(n,this.G(a,s,p))
s=o}if(s<a.length||r>0)B.a.k(n,this.aY(a,s))
return n},
aX(a,b){var t=b.length
if(t>a.length)return!1
return b===a.substring(0,t)},
G(a,b,c){return a.substring(b,A.es(b,c,a.length))},
aY(a,b){return this.G(a,b,null)},
bH(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.a(q,0)
if(q.charCodeAt(0)===133){t=J.fW(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.a(q,s)
r=q.charCodeAt(s)===133?J.fX(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
W(a,b){var t,s
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.c(B.W)
for(t=a,s="";;){if((b&1)===1)s=t+s
b=b>>>1
if(b===0)break
t+=t}return s},
bE(a,b,c){var t=b-a.length
if(t<=0)return a
return this.W(c,t)+a},
h(a){return a},
gn(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gt(a){return A.ai(u.N)},
gl(a){return a.length},
$if:1,
$icB:1,
$iw:1}
A.at.prototype={
h(a){return"LateInitializationError: "+this.a}}
A.cH.prototype={}
A.aO.prototype={}
A.Z.prototype={
gB(a){var t=this
return new A.au(t,t.gl(t),A.z(t).j("au<Z.E>"))},
gM(a){return this.gl(this)===0},
bD(a){var t,s,r=this,q=r.gl(r)
for(t=0,s="";t<q;++t){s+=A.o(r.L(0,t))
if(q!==r.gl(r))throw A.c(A.a6(r))}return s.charCodeAt(0)==0?s:s}}
A.au.prototype={
gu(){var t=this.d
return t==null?this.$ti.c.a(t):t},
p(){var t,s=this,r=s.a,q=J.dO(r),p=q.gl(r)
if(s.b!==p)throw A.c(A.a6(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.L(r,t);++s.c
return!0}}
A.C.prototype={}
A.b5.prototype={
gl(a){return this.a.length},
L(a,b){var t=this.a
return J.fC(t,t.length-1-b)}}
A.p.prototype={$r:"+(1,2)",$s:1}
A.aM.prototype={}
A.aL.prototype={
gM(a){return this.b.length===0},
h(a){return A.cw(this)},
$iO:1}
A.aN.prototype={
gl(a){return this.b.length},
gbd(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
br(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
q(a,b){if(!this.br(b))return null
return this.b[this.a[b]]},
J(a,b){var t,s,r,q
this.$ti.j("~(1,2)").a(b)
t=this.gbd()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])}}
A.cC.prototype={
$0(){return B.q.bA(1000*this.a.now())},
$S:0}
A.b6.prototype={}
A.cL.prototype={
I(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.b3.prototype={
h(a){return"Null check operator used on a null value"}}
A.bL.prototype={
h(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.cb.prototype={
h(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.cz.prototype={
h(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.a0.prototype={
h(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.fd(s==null?"unknown":s)+"'"},
$ia8:1,
gbL(){return this},
$C:"$1",
$R:1,
$D:null}
A.by.prototype={$C:"$0",$R:0}
A.bz.prototype={$C:"$2",$R:2}
A.c8.prototype={}
A.c6.prototype={
h(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.fd(t)+"'"}}
A.aq.prototype={
v(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.aq))return!1
return this.$_target===b.$_target&&this.a===b.a},
gn(a){return(A.f9(this.a)^A.c2(this.$_target))>>>0},
h(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.c3(this.a)+"'")}}
A.c4.prototype={
h(a){return"RuntimeError: "+this.a}}
A.X.prototype={
gl(a){return this.a},
gM(a){return this.a===0},
gU(){return new A.Y(this,A.z(this).j("Y<1>"))},
q(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.bB(b)},
bB(a){var t,s,r=this.d
if(r==null)return null
t=r[this.aN(a)]
s=this.aO(t,a)
if(s<0)return null
return t[s].b},
i(a,b,c){var t,s,r=this,q=A.z(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.ar(t==null?r.b=r.ab():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.ar(s==null?r.c=r.ab():s,b,c)}else r.bC(b,c)},
bC(a,b){var t,s,r,q,p=this,o=A.z(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.ab()
s=p.aN(a)
r=t[s]
if(r==null)t[s]=[p.ac(a,b)]
else{q=p.aO(r,a)
if(q>=0)r[q].b=b
else r.push(p.ac(a,b))}},
J(a,b){var t,s,r=this
A.z(r).j("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.c(A.a6(r))
t=t.c}},
ar(a,b,c){var t,s=A.z(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.ac(b,c)
else t.b=c},
ac(a,b){var t=this,s=A.z(t),r=new A.cu(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else t.f=t.f.c=r;++t.a
t.r=t.r+1&1073741823
return r},
aN(a){return J.N(a)&1073741823},
aO(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.an(a[s].a,b))return s
return-1},
h(a){return A.cw(this)},
ab(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$iek:1}
A.cu.prototype={}
A.Y.prototype={
gl(a){return this.a.a},
gM(a){return this.a.a===0},
gB(a){var t=this.a
return new A.bO(t,t.r,t.e,this.$ti.j("bO<1>"))}}
A.bO.prototype={
gu(){return this.d},
p(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.a6(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}}}
A.aW.prototype={
gl(a){return this.a.a},
gB(a){var t=this.a
return new A.bP(t,t.r,t.e,this.$ti.j("bP<1>"))}}
A.bP.prototype={
gu(){return this.d},
p(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.a6(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.b
s.c=t.c
return!0}}}
A.de.prototype={
$1(a){return this.a(a)},
$S:1}
A.df.prototype={
$2(a,b){return this.a(a,b)},
$S:3}
A.dg.prototype={
$1(a){return this.a(A.a4(a))},
$S:4}
A.af.prototype={
h(a){return this.aI(!1)},
aI(a){var t,s,r,q,p,o=this.bb(),n=this.aA(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.a(n,r)
p=n[r]
m=a?m+A.er(p):m+A.o(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
bb(){var t,s=this.$s
while($.d1.length<=s)B.a.k($.d1,null)
t=$.d1[s]
if(t==null){t=this.b3()
B.a.i($.d1,s,t)}return t},
b3(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=u.K,k=J.aP(m,l)
for(t=0;t<m;++t)k[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.i(k,r,s[t])}}return A.dr(k,l)}}
A.aD.prototype={
aA(){return[this.a,this.b]},
v(a,b){if(b==null)return!1
return b instanceof A.aD&&this.$s===b.$s&&J.an(this.a,b.a)&&J.an(this.b,b.b)},
gn(a){return A.ds(this.$s,this.a,this.b,B.l)}}
A.aT.prototype={
h(a){return"RegExp/"+this.a+"/"+this.b.flags},
gbf(){var t=this,s=t.c
if(s!=null)return s
s=t.b
return t.c=A.eg(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,"g")},
b4(){var t,s=this.a
if(!A.iQ(s,"(",0))return!1
t=this.b.unicode?"u":""
return new RegExp("(?:)|"+s,t).exec("").length>1},
bz(a){var t=this.b.exec(a)
if(t==null)return null
return new A.bh(t)},
aJ(a,b){return new A.cc(this,b,0)},
ba(a,b){var t,s=this.gbf()
if(s==null)s=A.dH(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.bh(t)},
$icB:1,
$ihi:1}
A.bh.prototype={
gan(){return this.b.index},
gag(){var t=this.b
return t.index+t[0].length},
$ibQ:1,
$icE:1}
A.cc.prototype={
gB(a){return new A.cO(this.a,this.b,this.c)}}
A.cO.prototype={
gu(){var t=this.d
return t==null?u.h.a(t):t},
p(){var t,s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
t=n.c
s=m.length
if(t<=s){r=n.a
q=r.ba(m,t)
if(q!=null){n.d=q
p=q.gag()
if(q.b.index===p){t=!1
if(r.b.unicode){r=n.c
o=r+1
if(o<s){if(!(r>=0&&r<s))return A.a(m,r)
r=m.charCodeAt(r)
if(r>=55296&&r<=56319){if(!(o>=0))return A.a(m,o)
t=m.charCodeAt(o)
t=t>=56320&&t<=57343}}}p=(t?p+1:p)+1}n.c=p
return!0}}n.b=n.d=null
return!1}}
A.c7.prototype={
gag(){return this.a+this.c.length},
$ibQ:1,
gan(){return this.a}}
A.cl.prototype={
gB(a){return new A.d2(this.a,this.b,this.c)}}
A.d2.prototype={
p(){var t,s,r=this,q=r.c,p=r.b,o=p.length,n=r.a,m=n.length
if(q+o>m){r.d=null
return!1}t=n.indexOf(p,q)
if(t<0){r.c=m+1
r.d=null
return!1}s=t+o
r.d=new A.c7(t,p)
r.c=s===r.c?s+1:s
return!0},
gu(){var t=this.d
t.toString
return t}}
A.cU.prototype={
D(){var t=this.b
if(t===this)throw A.c(A.ej(this.a))
return t}}
A.aa.prototype={
gt(a){return B.bb},
bo(a,b,c){var t=new DataView(a,b)
return t},
aK(a){return this.bo(a,0,null)},
$if:1,
$iaa:1}
A.b0.prototype={
gbp(a){if(((a.$flags|0)&2)!==0)return new A.d5(a.buffer)
else return a.buffer}}
A.d5.prototype={
aK(a){var t=A.ha(this.a,0,null)
t.$flags=3
return t}}
A.bT.prototype={
gt(a){return B.bc},
$if:1}
A.ax.prototype={
gl(a){return a.length},
$iG:1}
A.aZ.prototype={
q(a,b){A.ag(b,a,a.length)
return a[b]},
$id:1,
$ie:1}
A.b_.prototype={$id:1,$ie:1}
A.bU.prototype={
gt(a){return B.bd},
$if:1}
A.bV.prototype={
gt(a){return B.be},
$if:1}
A.bW.prototype={
gt(a){return B.bf},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1}
A.bX.prototype={
gt(a){return B.bg},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1,
$idm:1}
A.bY.prototype={
gt(a){return B.bh},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1}
A.bZ.prototype={
gt(a){return B.bj},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1,
$idw:1}
A.c_.prototype={
gt(a){return B.bk},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1}
A.b1.prototype={
gt(a){return B.bl},
gl(a){return a.length},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1}
A.b2.prototype={
gt(a){return B.bm},
gl(a){return a.length},
q(a,b){A.ag(b,a,a.length)
return a[b]},
$if:1,
$idx:1}
A.bi.prototype={}
A.bj.prototype={}
A.bk.prototype={}
A.bl.prototype={}
A.Q.prototype={
j(a){return A.br(v.typeUniverse,this,a)},
S(a){return A.eU(v.typeUniverse,this,a)}}
A.cf.prototype={}
A.d3.prototype={
h(a){return A.J(this.a,null)}}
A.ce.prototype={
h(a){return this.a}}
A.bn.prototype={}
A.ad.prototype={
gB(a){var t=this,s=new A.aC(t,t.r,A.z(t).j("aC<1>"))
s.c=t.e
return s},
gl(a){return this.a},
a1(a,b){var t=this.b5(b)
return t},
b5(a){var t=this.d
if(t==null)return!1
return this.az(t[this.av(a)],a)>=0},
k(a,b){var t,s,r=this
A.z(r).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.au(t==null?r.b=A.dE():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.au(s==null?r.c=A.dE():s,b)}else return r.b1(b)},
b1(a){var t,s,r,q=this
A.z(q).c.a(a)
t=q.d
if(t==null)t=q.d=A.dE()
s=q.av(a)
r=t[s]
if(r==null)t[s]=[q.a7(a)]
else{if(q.az(r,a)>=0)return!1
r.push(q.a7(a))}return!0},
au(a,b){A.z(this).c.a(b)
if(u.c8.a(a[b])!=null)return!1
a[b]=this.a7(b)
return!0},
a7(a){var t=this,s=new A.cj(A.z(t).c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
av(a){return J.N(a)&1073741823},
az(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.an(a[s].a,b))return s
return-1},
$iel:1}
A.cj.prototype={}
A.aC.prototype={
gu(){var t=this.d
return t==null?this.$ti.c.a(t):t},
p(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.c(A.a6(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.j("1?").a(s.a)
t.c=s.b
return!0}}}
A.cv.prototype={
$2(a,b){this.a.i(0,this.b.a(a),this.c.a(b))},
$S:5}
A.m.prototype={
gB(a){return new A.au(a,a.length,A.bt(a).j("au<m.E>"))},
L(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
gaP(a){return a.length!==0},
h(a){return A.dn(a,"[","]")}}
A.I.prototype={
J(a,b){var t,s,r,q=A.z(this)
q.j("~(I.K,I.V)").a(b)
for(t=this.gU(),t=t.gB(t),q=q.j("I.V");t.p();){s=t.gu()
r=this.q(0,s)
b.$2(s,r==null?q.a(r):r)}},
gl(a){var t=this.gU()
return t.gl(t)},
gM(a){var t=this.gU()
return t.gM(t)},
h(a){return A.cw(this)},
$iO:1}
A.cx.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.o(a)
s.a=(s.a+=t)+": "
t=A.o(b)
s.a+=t},
$S:2}
A.bs.prototype={}
A.aw.prototype={
q(a,b){return this.a.q(0,b)},
J(a,b){this.a.J(0,this.$ti.j("~(1,2)").a(b))},
gM(a){return this.a.a===0},
gl(a){return this.a.a},
h(a){return A.cw(this.a)},
$iO:1}
A.bd.prototype={}
A.az.prototype={
bn(a,b){var t,s,r
A.z(this).j("d<1>").a(b)
for(t=A.hB(b,b.r,A.z(b).c),s=t.$ti.c;t.p();){r=t.d
this.k(0,r==null?s.a(r):r)}},
h(a){return A.dn(this,"{","}")},
$id:1}
A.bm.prototype={}
A.aE.prototype={}
A.ch.prototype={
q(a,b){var t,s=this.b
if(s==null)return this.c.q(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.bg(b):t}},
gl(a){return this.b==null?this.c.a:this.a_().length},
gM(a){return this.gl(0)===0},
gU(){if(this.b==null){var t=this.c
return new A.Y(t,A.z(t).j("Y<1>"))}return new A.ci(this)},
J(a,b){var t,s,r,q,p=this
u.cQ.a(b)
if(p.b==null)return p.c.J(0,b)
t=p.a_()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.d9(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.c(A.a6(p))}},
a_(){var t=u.aL.a(this.c)
if(t==null)t=this.c=A.j(Object.keys(this.a),u.s)
return t},
bg(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.d9(this.a[a])
return this.b[a]=t}}
A.ci.prototype={
gl(a){return this.a.gl(0)},
L(a,b){var t=this.a
if(t.b==null)t=t.gU().L(0,b)
else{t=t.a_()
if(!(b>=0&&b<t.length))return A.a(t,b)
t=t[b]}return t},
gB(a){var t=this.a
if(t.b==null){t=t.gU()
t=t.gB(t)}else{t=t.a_()
t=new J.ao(t,t.length,A.aF(t).j("ao<1>"))}return t}}
A.cn.prototype={
bs(a){var t,s,r,q=A.es(0,null,a.length)
if(0===q)return new Uint8Array(0)
t=new A.cP()
s=t.bu(a,0,q)
s.toString
r=t.a
if(r<-1)A.aJ(A.V("Missing padding character",a,q))
if(r>0)A.aJ(A.V("Invalid length, must be multiple of four",a,q))
t.a=-1
return s}}
A.cP.prototype={
bu(a,b,c){var t,s=this,r=s.a
if(r<0){s.a=A.eC(a,b,c,r)
return null}if(b===c)return new Uint8Array(0)
t=A.ho(a,b,c,r)
s.a=A.hq(a,b,c,t,0,s.a)
return t}}
A.bA.prototype={}
A.bC.prototype={}
A.aV.prototype={
h(a){var t=A.bE(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.bN.prototype={
h(a){return"Cyclic error in JSON stringify"}}
A.bM.prototype={
bt(a,b){var t=A.io(a,this.gbv().a)
return t},
bw(a,b){var t=A.hA(a,this.gbx().b,null)
return t},
gbx(){return B.a0},
gbv(){return B.a_}}
A.ct.prototype={}
A.cs.prototype={}
A.cZ.prototype={
aS(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.f.G(a,s,r)
s=r+1
p=A.x(92)
t.a+=p
p=A.x(117)
t.a+=p
p=A.x(100)
t.a+=p
p=q>>>8&15
p=A.x(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.x(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.x(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.f.G(a,s,r)
s=r+1
p=A.x(92)
t.a+=p
switch(q){case 8:p=A.x(98)
t.a+=p
break
case 9:p=A.x(116)
t.a+=p
break
case 10:p=A.x(110)
t.a+=p
break
case 12:p=A.x(102)
t.a+=p
break
case 13:p=A.x(114)
t.a+=p
break
default:p=A.x(117)
t.a+=p
p=A.x(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.x(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.x(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.f.G(a,s,r)
s=r+1
p=A.x(92)
t.a+=p
p=A.x(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.f.G(a,s,n)},
a6(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.c(new A.bN(a,null))}B.a.k(t,a)},
a4(a){var t,s,r,q,p=this
if(p.aR(a))return
p.a6(a)
try{t=p.b.$1(a)
if(!p.aR(t)){r=A.eh(a,null,p.gaC())
throw A.c(r)}r=p.a
if(0>=r.length)return A.a(r,-1)
r.pop()}catch(q){s=A.fe(q)
r=A.eh(a,s,p.gaC())
throw A.c(r)}},
aR(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.q.h(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.aS(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.a6(a)
r.bJ(a)
t=r.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return!0}else if(u.W.b(a)){r.a6(a)
s=r.bK(a)
t=r.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return s}else return!1},
bJ(a){var t,s=this.c
s.a+="["
if(J.fD(a)){if(0>=a.length)return A.a(a,0)
this.a4(a[0])
for(t=1;t<a.length;++t){s.a+=","
this.a4(a[t])}}s.a+="]"},
bK(a){var t,s,r,q,p,o,n=this,m={}
if(a.gM(a)){n.c.a+="{}"
return!0}t=a.gl(a)*2
s=A.H(t,null,u.X)
r=m.a=0
m.b=!0
a.J(0,new A.d_(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.aS(A.a4(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.a(s,o)
n.a4(s[o])}q.a+="}"
return!0}}
A.d_.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.i(t,s.a++,a)
B.a.i(t,s.a++,b)},
$S:2}
A.cY.prototype={
gaC(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.n.prototype={
E(a){var t,s,r=this,q=r.c
if(q===0)return r
t=!r.a
s=r.b
q=A.y(q,s)
return new A.n(q===0?!1:t,s,q)},
b8(a){var t,s,r,q,p,o,n,m=this.c
if(m===0)return $.B()
t=m+a
s=this.b
r=new Uint16Array(t)
for(q=m-1,p=s.length;q>=0;--q){o=q+a
if(!(q<p))return A.a(s,q)
n=s[q]
if(!(o>=0&&o<t))return A.a(r,o)
r[o]=n}p=this.a
o=A.y(t,r)
return new A.n(o===0?!1:p,r,o)},
b9(a){var t,s,r,q,p,o,n,m,l=this,k=l.c
if(k===0)return $.B()
t=k-a
if(t<=0)return l.a?$.e0():$.B()
s=l.b
r=new Uint16Array(t)
for(q=s.length,p=a;p<k;++p){o=p-a
if(!(p>=0&&p<q))return A.a(s,p)
n=s[p]
if(!(o<t))return A.a(r,o)
r[o]=n}o=l.a
n=A.y(t,r)
m=new A.n(n===0?!1:o,r,n)
if(o)for(p=0;p<a;++p){if(!(p<q))return A.a(s,p)
if(s[p]!==0)return m.N(0,$.L())}return m},
F(a,b){var t,s,r,q,p,o=this
if(b<0)throw A.c(A.aK("shift-amount must be posititve "+b))
t=o.c
if(t===0)return o
s=B.b.m(b,16)
if(B.b.V(b,16)===0)return o.b8(s)
r=t+s+1
q=new Uint16Array(r)
A.eI(o.b,t,b,q)
t=o.a
p=A.y(r,q)
return new A.n(p===0?!1:t,q,p)},
al(a,b){var t,s,r,q,p,o,n,m,l,k=this
if(b<0)throw A.c(A.aK("shift-amount must be posititve "+b))
t=k.c
if(t===0)return k
s=B.b.m(b,16)
r=B.b.V(b,16)
if(r===0)return k.b9(s)
q=t-s
if(q<=0)return k.a?$.e0():$.B()
p=k.b
o=new Uint16Array(q)
A.hx(p,t,b,o)
t=k.a
n=A.y(q,o)
m=new A.n(n===0?!1:t,o,n)
if(t){t=p.length
if(!(s>=0&&s<t))return A.a(p,s)
if((p[s]&B.b.F(1,r)-1)!==0)return m.N(0,$.L())
for(l=0;l<s;++l){if(!(l<t))return A.a(p,l)
if(p[l]!==0)return m.N(0,$.L())}}return m},
P(a,b){var t,s=this.a
if(s===b.a){t=A.cR(this.b,this.c,b.b,b.c)
return s?0-t:t}return s?-1:1},
O(a,b){var t,s,r,q=this,p=q.c,o=a.c
if(p<o)return a.O(q,b)
if(p===0)return $.B()
if(o===0)return q.a===b?q:q.E(0)
t=p+1
s=new Uint16Array(t)
A.hs(q.b,p,a.b,o,s)
r=A.y(t,s)
return new A.n(r===0?!1:b,s,r)},
C(a,b){var t,s,r,q=this,p=q.c
if(p===0)return $.B()
t=a.c
if(t===0)return q.a===b?q:q.E(0)
s=new Uint16Array(p)
A.cd(q.b,p,a.b,t,s)
r=A.y(p,s)
return new A.n(r===0?!1:b,s,r)},
ap(a,b){var t,s,r,q,p,o,n,m,l=this.c,k=a.c
l=l<k?l:k
t=this.b
s=a.b
r=new Uint16Array(l)
for(q=t.length,p=s.length,o=0;o<l;++o){if(!(o<q))return A.a(t,o)
n=t[o]
if(!(o<p))return A.a(s,o)
m=s[o]
if(!(o<l))return A.a(r,o)
r[o]=n&m}q=A.y(l,r)
return new A.n(q===0?!1:b,r,q)},
ao(a,b){var t,s,r,q,p,o=this.c,n=this.b,m=a.b,l=new Uint16Array(o),k=a.c
if(o<k)k=o
for(t=n.length,s=m.length,r=0;r<k;++r){if(!(r<t))return A.a(n,r)
q=n[r]
if(!(r<s))return A.a(m,r)
p=m[r]
if(!(r<o))return A.a(l,r)
l[r]=q&~p}for(r=k;r<o;++r){if(!(r>=0&&r<t))return A.a(n,r)
s=n[r]
if(!(r<o))return A.a(l,r)
l[r]=s}t=A.y(o,l)
return new A.n(t===0?!1:b,l,t)},
aq(a,b){var t,s,r,q,p,o,n,m,l=this.c,k=a.c,j=l>k?l:k,i=this.b,h=a.b,g=new Uint16Array(j)
if(l<k){t=l
s=a}else{t=k
s=this}for(r=i.length,q=h.length,p=0;p<t;++p){if(!(p<r))return A.a(i,p)
o=i[p]
if(!(p<q))return A.a(h,p)
n=h[p]
if(!(p<j))return A.a(g,p)
g[p]=o|n}m=s.b
for(r=m.length,p=t;p<j;++p){if(!(p>=0&&p<r))return A.a(m,p)
q=m[p]
if(!(p<j))return A.a(g,p)
g[p]=q}r=A.y(j,g)
return new A.n(r===0?!1:b,g,r)},
a5(a,b){var t,s,r,q,p,o,n,m,l=this.c,k=a.c,j=l>k?l:k,i=this.b,h=a.b,g=new Uint16Array(j)
if(l<k){t=l
s=a}else{t=k
s=this}for(r=i.length,q=h.length,p=0;p<t;++p){if(!(p<r))return A.a(i,p)
o=i[p]
if(!(p<q))return A.a(h,p)
n=h[p]
if(!(p<j))return A.a(g,p)
g[p]=o^n}m=s.b
for(r=m.length,p=t;p<j;++p){if(!(p>=0&&p<r))return A.a(m,p)
q=m[p]
if(!(p<j))return A.a(g,p)
g[p]=q}r=A.y(j,g)
return new A.n(r===0?!1:b,g,r)},
R(a,b){var t,s,r,q=this
u.x.a(b)
if(q.c===0||b.c===0)return $.B()
t=q.a
if(t===b.a){if(t){t=$.L()
return q.C(t,!0).aq(b.C(t,!0),!0).O(t,!0)}return q.ap(b,!1)}if(t){s=q
r=b}else{s=b
r=q}return r.ao(s.C($.L(),!1),!1)},
aT(a,b){var t,s,r,q=this
if(q.c===0)return b
if(b.c===0)return q
t=q.a
if(t===b.a){if(t){t=$.L()
return q.C(t,!0).ap(b.C(t,!0),!0).O(t,!0)}return q.aq(b,!1)}if(t){s=q
r=b}else{s=b
r=q}t=$.L()
return s.C(t,!0).ao(r,!0).O(t,!0)},
A(a,b){var t,s,r,q=this
if(q.c===0)return b
if(b.c===0)return q
t=q.a
if(t===b.a){if(t){t=$.L()
return q.C(t,!0).a5(b.C(t,!0),!1)}return q.a5(b,!1)}if(t){s=q
r=b}else{s=b
r=q}t=$.L()
return r.a5(s.C(t,!0),!0).O(t,!0)},
ak(a,b){var t,s,r=this,q=r.c
if(q===0)return b
t=b.c
if(t===0)return r
s=r.a
if(s===b.a)return r.O(b,s)
if(A.cR(r.b,q,b.b,t)>=0)return r.C(b,s)
return b.C(r,!s)},
N(a,b){var t,s,r=this,q=r.c
if(q===0)return b.E(0)
t=b.c
if(t===0)return r
s=r.a
if(s!==b.a)return r.O(b,s)
if(A.cR(r.b,q,b.b,t)>=0)return r.C(b,s)
return b.C(r,!s)},
W(a,b){var t,s,r,q,p,o,n,m=this.c,l=b.c
if(m===0||l===0)return $.B()
t=m+l
s=this.b
r=b.b
q=new Uint16Array(t)
for(p=r.length,o=0;o<l;){if(!(o<p))return A.a(r,o)
A.eJ(r[o],s,0,q,o,m);++o}p=this.a!==b.a
n=A.y(t,q)
return new A.n(n===0?!1:p,q,n)},
b7(a){var t,s,r,q
if(this.c<a.c)return $.B()
this.aw(a)
t=$.dz.D()-$.bg.D()
s=A.dB($.dy.D(),$.bg.D(),$.dz.D(),t)
r=A.y(t,s)
q=new A.n(!1,s,r)
return this.a!==a.a&&r>0?q.E(0):q},
bl(a){var t,s,r,q=this
if(q.c<a.c)return q
q.aw(a)
t=A.dB($.dy.D(),0,$.bg.D(),$.bg.D())
s=A.y($.bg.D(),t)
r=new A.n(!1,t,s)
if($.dA.D()>0)r=r.al(0,$.dA.D())
return q.a&&r.c>0?r.E(0):r},
aw(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=d.c
if(c===$.eF&&a.c===$.eH&&d.b===$.eE&&a.b===$.eG)return
t=a.b
s=a.c
r=s-1
if(!(r>=0&&r<t.length))return A.a(t,r)
q=16-B.b.gaL(t[r])
if(q>0){p=new Uint16Array(s+5)
o=A.eD(t,s,q,p)
n=new Uint16Array(c+5)
m=A.eD(d.b,c,q,n)}else{n=A.dB(d.b,0,c,c+2)
o=s
p=t
m=c}r=o-1
if(!(r>=0&&r<p.length))return A.a(p,r)
l=p[r]
k=m-o
j=new Uint16Array(m)
i=A.dD(p,o,k,j)
h=m+1
r=n.$flags|0
if(A.cR(n,m,j,i)>=0){r&2&&A.q(n)
if(!(m>=0&&m<n.length))return A.a(n,m)
n[m]=1
A.cd(n,h,j,i,n)}else{r&2&&A.q(n)
if(!(m>=0&&m<n.length))return A.a(n,m)
n[m]=0}r=o+2
g=new Uint16Array(r)
if(!(o>=0&&o<r))return A.a(g,o)
g[o]=1
A.cd(g,o+1,p,o,g)
f=m-1
for(r=n.length;k>0;){e=A.ht(l,n,f);--k
A.eJ(e,g,0,n,k,o)
if(!(f>=0&&f<r))return A.a(n,f)
if(n[f]<e){i=A.dD(g,o,k,j)
A.cd(n,h,j,i,n)
while(--e,n[f]<e)A.cd(n,h,j,i,n)}--f}$.eE=d.b
$.eF=c
$.eG=t
$.eH=s
$.dy.b=n
$.dz.b=h
$.bg.b=o
$.dA.b=q},
gn(a){var t,s,r,q,p=new A.cS(),o=this.c
if(o===0)return 6707
t=this.a?83585:429689
for(s=this.b,r=s.length,q=0;q<o;++q){if(!(q<r))return A.a(s,q)
t=p.$2(t,s[q])}return new A.cT().$1(t)},
v(a,b){if(b==null)return!1
return b instanceof A.n&&this.P(0,b)===0},
bG(a,b){var t=$.L(),s=t.F(0,b-1)
return this.R(0,s.N(0,t)).N(0,this.R(0,s))},
a3(a){var t,s,r,q
for(t=this.c-1,s=this.b,r=s.length,q=0;t>=0;--t){if(!(t<r))return A.a(s,t)
q=q*65536+s[t]}return this.a?-q:q},
h(a){var t,s,r,q,p,o=this,n=o.c
if(n===0)return"0"
if(n===1){if(o.a){n=o.b
if(0>=n.length)return A.a(n,0)
return B.b.h(-n[0])}n=o.b
if(0>=n.length)return A.a(n,0)
return B.b.h(n[0])}t=A.j([],u.s)
n=o.a
s=n?o.E(0):o
while(s.c>1){r=$.e_()
if(r.c===0)A.aJ(B.P)
q=s.bl(r).h(0)
B.a.k(t,q)
p=q.length
if(p===1)B.a.k(t,"000")
if(p===2)B.a.k(t,"00")
if(p===3)B.a.k(t,"0")
s=s.b7(r)}r=s.b
if(0>=r.length)return A.a(r,0)
B.a.k(t,B.b.h(r[0]))
if(n)B.a.k(t,"-")
return new A.b5(t,u.r).bD(0)},
$iap:1}
A.cS.prototype={
$2(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
$S:6}
A.cT.prototype={
$1(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
$S:7}
A.bD.prototype={
v(a,b){if(b==null)return!1
return b instanceof A.bD&&this.a===b.a},
gn(a){return B.b.gn(this.a)},
h(a){var t,s,r,q,p,o=this.a,n=B.b.m(o,36e8),m=o%36e8
if(o<0){n=0-n
o=0-m
t="-"}else{o=m
t=""}s=B.b.m(o,6e7)
o%=6e7
r=s<10?"0":""
q=B.b.m(o,1e6)
p=q<10?"0":""
return t+n+":"+r+s+":"+p+q+"."+B.f.bE(B.b.h(o%1e6),6,"0")}}
A.cW.prototype={
h(a){return this.a8()}}
A.h.prototype={}
A.bw.prototype={
h(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bE(t)
return"Assertion failed"}}
A.bc.prototype={}
A.U.prototype={
gaa(){return"Invalid argument"+(!this.a?"(s)":"")},
ga9(){return""},
h(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gaa()+r+p
if(!t.a)return o
return o+t.ga9()+": "+A.bE(t.gah())},
gah(){return this.b}}
A.ay.prototype={
gah(){return A.eY(this.b)},
gaa(){return"RangeError"},
ga9(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.o(r):""
else if(r==null)t=": Not greater than or equal to "+A.o(s)
else if(r>s)t=": Not in inclusive range "+A.o(s)+".."+A.o(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.o(s)
return t}}
A.bF.prototype={
gah(){return A.T(this.b)},
gaa(){return"RangeError"},
ga9(){if(A.T(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gl(a){return this.f}}
A.be.prototype={
h(a){return"Unsupported operation: "+this.a}}
A.ca.prototype={
h(a){return"UnimplementedError: "+this.a}}
A.bb.prototype={
h(a){return"Bad state: "+this.a}}
A.bB.prototype={
h(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bE(t)+"."}}
A.c0.prototype={
h(a){return"Out of Memory"},
$ih:1}
A.ba.prototype={
h(a){return"Stack Overflow"},
$ih:1}
A.cq.prototype={
h(a){var t,s,r,q,p,o,n,m,l,k,j,i=this.a,h=""!==i?"FormatException: "+i:"FormatException",g=this.c,f=this.b
if(typeof f=="string"){if(g!=null)t=g<0||g>f.length
else t=!1
if(t)g=null
if(g==null){if(f.length>78)f=B.f.G(f,0,75)+"..."
return h+"\n"+f}for(s=f.length,r=1,q=0,p=!1,o=0;o<g;++o){if(!(o<s))return A.a(f,o)
n=f.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}h=r>1?h+(" (at line "+r+", character "+(g-q+1)+")\n"):h+(" (at character "+(g+1)+")\n")
for(o=g;o<s;++o){if(!(o>=0))return A.a(f,o)
n=f.charCodeAt(o)
if(n===10||n===13){s=o
break}}m=""
if(s-q>78){l="..."
if(g-q<75){k=q+75
j=q}else{if(s-g<75){j=s-75
k=s
l=""}else{j=g-36
k=g+36}m="..."}}else{k=s
j=q
l=""}return h+m+B.f.G(f,j,k)+l+"\n"+B.f.W(" ",g-j+m.length)+"^\n"}else return g!=null?h+(" (at offset "+A.o(g)+")"):h}}
A.bG.prototype={
h(a){return"IntegerDivisionByZeroException"},
$ih:1}
A.d.prototype={
gl(a){var t,s=this.gB(this)
for(t=0;s.p();)++t
return t},
L(a,b){var t,s
A.hh(b,"index")
t=this.gB(this)
for(s=b;t.p();){if(s===0)return t.gu();--s}throw A.c(A.ee(b,b-s,this,"index"))},
h(a){return A.fV(this,"(",")")}}
A.ab.prototype={
gn(a){return A.k.prototype.gn.call(this,0)},
h(a){return"null"}}
A.k.prototype={$ik:1,
v(a,b){return this===b},
gn(a){return A.c2(this)},
h(a){return"Instance of '"+A.c3(this)+"'"},
gt(a){return A.iD(this)},
toString(){return this.h(this)}}
A.cI.prototype={
ga2(){var t,s=this.b
if(s==null)s=$.dt.$0()
t=s-this.a
if($.dZ()===1e6)return t
return t*1000}}
A.aA.prototype={
gl(a){return this.a.length},
h(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ihl:1}
A.d0.prototype={
b_(a){var t,s,r,q,p,o,n,m=this,l=4294967296
do{t=a>>>0
a=B.b.m(a-t,l)
s=a>>>0
a=B.b.m(a-s,l)
r=(~t>>>0)+(t<<21>>>0)
q=r>>>0
s=(~s>>>0)+((s<<21|t>>>11)>>>0)+B.b.m(r-q,l)>>>0
r=((q^(q>>>24|s<<8))>>>0)*265
t=r>>>0
s=((s^s>>>24)>>>0)*265+B.b.m(r-t,l)>>>0
r=((t^(t>>>14|s<<18))>>>0)*21
t=r>>>0
s=((s^s>>>14)>>>0)*21+B.b.m(r-t,l)>>>0
t=(t^(t>>>28|s<<4))>>>0
s=(s^s>>>28)>>>0
r=(t<<31>>>0)+t
q=r>>>0
p=B.b.m(r-q,l)
r=m.a*1037
o=m.a=r>>>0
n=m.b*1037+B.b.m(r-o,l)>>>0
m.b=n
o=(o^q)>>>0
m.a=o
p=(n^s+((s<<31|t>>>1)>>>0)+p>>>0)>>>0
m.b=p}while(a!==0)
if(p===0&&o===0)m.a=23063
m.T()
m.T()
m.T()
m.T()},
T(){var t=this,s=t.a,r=4294901760*s,q=r>>>0,p=55905*s,o=p>>>0,n=o+q+t.b
s=n>>>0
t.a=s
t.b=B.b.m(p-o+(r-q)+(n-s),4294967296)>>>0},
aQ(a){var t,s,r,q=this
if(a<=0||a>4294967296)throw A.c(A.hg("max must be in range 0 < max \u2264 2^32, was "+a))
t=a-1
if((a&t)>>>0===0){q.T()
return(q.a&t)>>>0}do{q.T()
s=q.a
r=s%a}while(s-r+a>=4294967296)
return r}}
A.co.prototype={
bF(){var t,s,r,q
for(t=this.r,s=t.length-3,r=1;s>=this.x;s-=2){if(!(s<t.length))return A.a(t,s)
q=t[s].P(0,this.f)
if(q===0)++r}return r},
aV(){var t,s,r,q=this
for(t=q.a,s=0;s<8;++s)for(r=0;r<8;++r)B.a.i(t[s],r,null)
for(s=0;s<8;++s){B.a.i(t[s],0,new A.S(B.n[s],B.e))
B.a.i(t[s],1,B.aW)
B.a.i(t[s],6,B.aV)
B.a.i(t[s],7,new A.S(B.m[s],B.c))}q.b=B.c
q.d=q.c=!1
B.a.af(q.e)
q.bj()
q.bi()
t=q.r
B.a.af(t)
B.a.k(t,q.f)
B.a.af(q.w)
q.x=0},
bi(){var t,s,r,q,p,o,n=this,m=n.y
B.a.i(m,0,null)
B.a.i(m,1,null)
n.z=0
t=n.Q
B.a.i(t,0,0)
B.a.i(t,1,0)
for(s=n.a,r=0;r<8;++r)for(q=0;q<8;++q){p=s[r][q]
if(p==null)continue;++n.z
o=p.a
if(o===B.d)B.a.i(m,p.b.a,new A.t(r,q))
else if(o!==B.h){o=p.b.a
if(!(o<2))return A.a(t,o)
B.a.i(t,o,t[o]+1)}}},
bj(){var t,s,r,q,p,o,n,m,l=this,k=$.B()
for(t=l.a,s=0;s<8;++s)for(r=s*8,q=0;q<8;++q){p=t[s][q]
if(p!=null){o=p.a.a*2+p.b.a
n=r+q
m=$.a5().a
m===$&&A.D()
if(!(o<12))return A.a(m,o)
m=m[o]
if(!(n<64))return A.a(m,n)
k=k.A(0,m[n])}}if(l.b===B.e){t=$.a5().b
t===$&&A.D()
k=k.A(0,t)}if(l.c){t=$.a5().c
t===$&&A.D()
k=k.A(0,t[0])}if(l.d){t=$.a5().c
t===$&&A.D()
k=k.A(0,t[1])}l.f=k},
X(a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=c.a,a=a1.a,a0=a.a
if(!(a0>=0&&a0<8))return A.a(b,a0)
t=b[a0]
s=a.b
if(!(s>=0&&s<8))return A.a(t,s)
r=t[s]
if(r==null)throw A.c(A.ex("makeMove: no piece at "+a.h(0)))
a=a1.b
q=a.a
if(!(q>=0&&q<8))return A.a(b,q)
p=b[q]
o=a.b
if(!(o>=0&&o<8))return A.a(p,o)
n=p[o]
p=r.b
m=p===B.c
l=m?c.c:c.d
k=r.a
j=k===B.d
if(j){i=Math.abs(q-a0)
h=Math.abs(o-s)
if(!(i===1&&h===2)){g=i===2&&h===1
f=g}else f=!0}else f=!1
g=a1.c
e=g!=null
d=e?new A.S(g,p):r
B.a.i(t,s,null)
B.a.i(b[q],o,d)
if(j)B.a.i(c.y,p.a,a)
else if(e){b=c.Q
a=p.a
if(!(a<2))return A.a(b,a)
B.a.i(b,a,b[a]+1)}b=n==null
a=!b
if(a){--c.z
t=n.a
if(t===B.d)B.a.i(c.y,n.b.a,null)
else if(t!==B.h){t=c.Q
j=n.b.a
if(!(j<2))return A.a(t,j)
B.a.i(t,j,t[j]-1)}}a0=c.f=c.f.A(0,A.bf(k,p,a0,s))
a=a?c.f=a0.A(0,A.bf(n.a,n.b,q,o)):a0
o=a.A(0,A.bf(d.a,d.b,q,o))
c.f=o
q=$.a5()
a=q.b
a===$&&A.D()
a=o.A(0,a)
c.f=a
if(f&&!l){a0=q.c
a0===$&&A.D()
p=p.a
if(!(p<2))return A.a(a0,p)
c.f=a.A(0,a0[p])}if(f)if(m)c.c=!0
else c.d=!0
B.a.k(c.e,new A.cg(a1,r,n,l))
c.b=c.b===B.c?B.e:B.c
B.a.k(c.w,c.x)
if(!b||e)c.x=c.r.length
B.a.k(c.r,c.f)},
Y(){var t,s,r,q,p,o,n,m,l,k,j,i=this,h=i.e,g=h.length
if(g===0)throw A.c(A.ex("undoMove: no move to undo"))
if(0>=g)return A.a(h,-1)
t=h.pop()
h=i.r
if(0>=h.length)return A.a(h,-1)
h.pop()
h=i.w
if(0>=h.length)return A.a(h,-1)
i.x=h.pop()
s=t.a
h=i.a
g=s.b
r=g.a
if(!(r>=0&&r<8))return A.a(h,r)
q=h[r]
p=g.b
if(!(p>=0&&p<8))return A.a(q,p)
o=q[p]
q=s.a
n=q.a
if(!(n>=0&&n<8))return A.a(h,n)
m=q.b
l=t.b
B.a.i(h[n],m,l)
k=t.c
B.a.i(h[r],p,k)
h=l.a
if(h===B.d)B.a.i(i.y,l.b.a,q)
else if(s.c!=null){q=i.Q
j=l.b.a
if(!(j<2))return A.a(q,j)
B.a.i(q,j,q[j]-1)}q=k!=null
if(q){++i.z
j=k.a
if(j===B.d)B.a.i(i.y,k.b.a,g)
else if(j!==B.h){g=i.Q
j=k.b.a
if(!(j<2))return A.a(g,j)
B.a.i(g,j,g[j]+1)}}g=l.b
m=i.f=i.f.A(0,A.bf(h,g,n,m))
if(q){h=m.A(0,A.bf(k.a,k.b,r,p))
i.f=h}else h=m
if(o!=null)h=i.f=h.A(0,A.bf(o.a,o.b,r,p))
r=$.a5()
q=r.b
q===$&&A.D()
q=h.A(0,q)
i.f=q
h=g===B.c
p=t.d
if(h?i.c!==p:i.d!==p){r=r.c
r===$&&A.D()
g=g.a
if(!(g<2))return A.a(r,g)
i.f=q.A(0,r[g])}if(h)i.c=p
else i.d=p
i.b=i.b===B.c?B.e:B.c}}
A.cg.prototype={}
A.a7.prototype={
bc(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=new Int32Array(768)
for(t=this.a,s=t.length,r=this.b,q=r.length,p=0;p<6;++p){o=B.r[p].a
if(!(o<s))return A.a(t,o)
n=t[o]
if(!(o<q))return A.a(r,o)
m=r[o]
for(l=m.length,o*=2,k=0;k<2;++k){j=B.ao[k]
i=(o+j.a)*64
for(h=j===B.c,g=0;g<8;++g)for(f=i+g*8,e=0;e<8;++e){d=h?e:7-e
c=f+e
if(!(d<l))return A.a(m,d)
b=m[d]
if(!(g<b.length))return A.a(b,g)
b=b[g]
if(!(c<768))return A.a(a,c)
a[c]=n+b}}}return a}}
A.A.prototype={
v(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.A&&b.a.v(0,s.a)&&b.b.v(0,s.b)&&b.c==s.c
else t=!0
return t},
gn(a){return A.ds(this.a,this.b,this.c,B.l)},
h(a){var t=this.a.h(0),s=this.b.h(0),r=this.c
r=r!=null?"="+r.c:""
return t+"-"+s+r}}
A.cy.prototype={
$3(a,b,c){var t,s,r,q,p,o,n,m=this
if(a<0||a>=8||b<0||b>=8)return
t=new A.t(a,b)
if(m.b.a1(0,t))return
s=m.c.a
if(!(a>=0&&a<8))return A.a(s,a)
s=s[a]
if(!(b>=0&&b<8))return A.a(s,b)
r=s[b]
if(r==null||r.b!==m.d||r.a!==c)return
q=m.e.$1(c)
s=m.a
p=s.a
o=s.b
n=!0
if(!(q<o))if(p!=null)if(q===o){o=p.a
if(a>=o)o=a===o&&b<p.b
else o=n}else o=!1
else o=!1
else o=n
if(o){s.b=q
s.a=t}},
$S:8}
A.cA.prototype={
gl(a){var t=this.a
return t.gl(t)}}
A.b9.prototype={
a8(){return"Side."+this.b}}
A.E.prototype={
a8(){return"PieceType."+this.b}}
A.S.prototype={
v(a,b){var t
if(b==null)return!1
if(this!==b)t=b instanceof A.S&&b.a===this.a&&b.b===this.b
else t=!0
return t},
gn(a){return A.ds(this.a,this.b,B.l,B.l)},
h(a){var t=this.a.c
return this.b===B.c?t:t.toLowerCase()}}
A.c5.prototype={}
A.b8.prototype={}
A.cF.prototype={
aU(a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=null,a0=b.a
if(a0==null)t=a
else{s=a1.f
t=a0.a.q(0,s)}if(t!=null)if(B.a.a1(A.bR(a1,!1),t)){b.ax=!1
return new A.b8(t,0,0)}b.x=0
b.ax=!1
b.at=a2
a0=new A.cI()
$.dZ()
s=$.dt.$0()
a0.a=s
a0.b=null
b.as=a0
if(!b.b.Q||b.z==null)b.z=new A.cK(262143,A.H(262144,a,u.E))
a0=b.z
a0.toString
b.y=a0
r=2*a3+8+2
a0=u.q
q=J.aP(r,a0)
for(s=u.o,p=0;p<r;++p)q[p]=A.j([null,null],s)
s=u.A
b.Q=s.a(q)
b.w=a3>=6
q=J.aP(2,u.f)
for(o=u.S,n=u.p,m=0;m<2;++m){l=A.j(new Array(64),n)
for(k=0;k<64;++k)l[k]=A.H(64,0,o)
q[m]=l}b.f=u.M.a(q)
q=J.aP(2,a0)
for(a0=u.ab,j=0;j<2;++j)q[j]=A.H(4096,a,a0)
b.r=s.a(q)
for(i=a,h=0,g=0,f=1;f<=a3;++f,g=c){a0=b.as
e=a0==null?a:a0.ga2()
if(e==null)e=0
d=b.bm(a1,f,i)
if(b.ax){if(i==null)i=d.a
break}i=d.a
if(i==null)return new A.b8(a,d.b,b.x)
h=d.b
if(Math.abs(h)>=999e3)break
a0=b.as
a0=a0==null?a:a0.ga2()
c=(a0==null?0:a0)-e
if(!b.b2(c,g))break}return new A.b8(i,h,b.x)},
b2(a,b){var t,s=this.as
if(s==null)return!0
t=b===0?2:B.q.aM(a/b,2,6)
return s.ga2()+a*t<=this.at.a},
aB(){var t,s=this
if(s.ax)return!0
t=s.as
if(t==null)return!1
if((s.x&2047)!==0)return!1
if(A.e8(t.ga2(),0).a<s.at.a)return!1
return s.ax=!0},
bm(a,b,c){var t,s,r,q,p,o,n,m,l,k=this,j=-1000001,i=A.bR(a,!1)
if(i.length===0)return new A.ck(null,A.aY(a,a.b)?-1e6:0)
t=k.ad(a,i,c,0)
A.cG(i,t,0)
s=B.a.gby(i)
for(r=b-1,q=j,p=q,o=0;o<i.length;++o){A.cG(i,t,o)
if(!(o<i.length))return A.a(i,o)
n=i[o]
a.X(n)
m=-q
if(o>0){l=-k.H(a,r,m-1,m,1)
if(!k.ax&&l>q)l=-k.H(a,r,j,m,1)}else l=-k.H(a,r,j,m,1)
a.Y()
if(k.ax)break
if(l>p){p=l
s=n}if(l>q)q=l}return new A.ck(s,p)},
H(b8,b9,c0,c1,c2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7=this;++b7.x
if(b7.aB())return 0
if(c2>0&&b8.bF()>=2)return 0
t=A.aY(b8,b8.b)
s=b8.f
r=b7.c
if(r!=null){q=r.aj(b8)
if(q!=null&&q!==3)switch(q){case 1:return 1e6-(1000-b9)
case 2:return-(1e6-(1000-b9))
case 0:return 0}}p=b7.y
p===$&&A.D()
o=p.aj(s)
if(o!=null){n=o.e
if(o.b>=b9){switch(o.d.a){case 0:return o.c
case 1:m=o.c
m=m>c0?m:c0
l=c1
break
case 2:l=o.c
l=l<c1?l:c1
m=c0
break
default:l=c1
m=c0}if(m>=l)return o.c}else{l=c1
m=c0}}else{l=c1
m=c0
n=null}if(b9===0)return b7.aD(b8,m,l,8,t)
k=!1
if(c1-c0<=1)if(!t){if(m>-999e3)if(l<999e3){p=b8.Q
j=b8.b.a
if(!(j<2))return A.a(p,j)
j=p[j]>0
p=j}else p=k
else p=k
k=p}if(k&&b9<=3){i=b7.a0(b8.b,b8)
if(i-120*b9>=l)return l}else i=null
p=!1
if(!t)if(b9>=3)if(b8.as===0){p=b8.Q
j=b8.b.a
if(!(j<2))return A.a(p,j)
j=p[j]>0
p=j}if(p){p=b8.f
j=$.a5().b
j===$&&A.D()
b8.f=p.A(0,j)
b8.b=b8.b===B.c?B.e:B.c;++b8.as
p=-l
p=b7.H(b8,b9-1-2,p,p+1,c2+1);--b8.as
b8.f=b8.f.A(0,j)
b8.b=b8.b===B.c?B.e:B.c
if(b7.ax)return 0
if(-p>=l)return l}h=A.bR(b8,!1)
if(h.length===0)return t?-(1e6-(1000-b9)):0
g=b7.ad(b8,h,n,c2)
f=k&&b9<=2
e=k&&b9<=3?3+b9*b9:h.length
if(f)i=i==null?b7.a0(b8.b,b8):i
for(p=b9-1,j=-l,d=c2+1,c=b8.a,b=150*b9,a=b9>=3,a0=!t,a1=b9-2,a2=-1000001,a3=null,a4=0;a4<h.length;++a4){A.cG(h,g,a4)
if(!(a4<h.length))return A.a(h,a4)
a5=h[a4]
a6=a5.b
a7=a6.a
if(!(a7>=0&&a7<8))return A.a(c,a7)
a7=c[a7]
a6=a6.b
if(!(a6>=0&&a6<8))return A.a(a7,a6)
a8=a7[a6]==null
b8.X(a5)
a9=A.aY(b8,b8.b)
if(a8&&a4>0&&!a9){if(a4<e)if(f){i.toString
a6=i+b<=m
b0=a6}else b0=!1
else b0=!0
if(b0){b8.Y()
B.a.i(g,a4,-1073741824)
continue}}b1=a&&a4>=3&&a8&&a0&&!a9
if(a4>0){a6=b1?2:1
a7=-m
b2=a7-1
b3=-b7.H(b8,b9-a6,b2,a7,d)
if(b1&&!b7.ax&&b3>m)b3=-b7.H(b8,p,b2,a7,d)
if(!b7.ax&&b3>m&&b3<l)b3=-b7.H(b8,p,j,a7,d)}else{a6=-m
if(b1){b3=-b7.H(b8,a1,a6-1,a6,d)
if(!b7.ax&&b3>m)b3=-b7.H(b8,p,j,a6,d)}else b3=-b7.H(b8,p,j,a6,d)}b8.Y()
if(b7.ax)return 0
if(b3>a2){a3=a5
a2=b3}if(a2>m)m=a2
if(m>=l){if(a8){b7.bk(c2,a5)
b7.aE(b8.b,a5,b9)
for(p=g.length,j=-b9,b4=0;b4<a4;++b4){if(!(b4<h.length))return A.a(h,b4)
b5=h[b4]
if(!(b4<p))return A.a(g,b4)
if(g[b4]!==-1073741824){d=b5.b
b=d.a
if(!(b>=0&&b<8))return A.a(c,b)
b=c[b]
d=d.b
if(!(d>=0&&d<8))return A.a(b,d)
d=b[d]==null}else d=!1
if(d)b7.aE(b8.b,b5,j)}}break}}if(!b7.ax&&Math.abs(a2)<999e3){if(a2<=c0)b6=B.ba
else b6=a2>=l?B.b9:B.b8
p=b7.y
B.a.i(p.b,s.R(0,A.cQ(p.a)).a3(0),new A.c9(s,b9,a2,b6,a3))}return a2},
aD(a,b,a0,a1,a2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this;++c.x
if(c.aB())return 0
if(a2==null)a2=A.aY(a,a.b)
t=a2?0:c.a0(a.b,a)
if(!a2){if(t>=a0)return a0
if(t>b)b=t}if(a1===0)return a2?c.a0(a.b,a):t
if(a2){s=A.bR(a,!1)
if(s.length===0)return-(1e6-(1000-a1))}else{s=A.j([],u._)
for(r=A.bR(a,!0),q=r.length,p=a.a,o=u.S,n=0;n<r.length;r.length===q||(0,A.dk)(r),++n){m=r[n]
l=m.b
k=l.a
if(!(k>=0&&k<8))return A.a(p,k)
k=p[k]
l=l.b
if(!(l>=0&&l<8))return A.a(k,l)
l=k[l].a
k=$.F
if(k==null){j=A.av(B.o,!1,o)
j.$flags=3
k=$.F=new A.a7(j,$.bu(),192,20,23,7,16,1)
i=k}else i=k
k=k.a
h=l.a
if(!(h<k.length))return A.a(k,h)
h=t+k[h]+120<b
k=h
if(k)continue
k=m.a
h=k.a
if(!(h>=0&&h<8))return A.a(p,h)
h=p[h]
k=k.b
if(!(k>=0&&k<8))return A.a(h,k)
g=h[k]
if(g!=null){k=g.a
if(k===B.d)k=3e4
else{if(i==null){j=A.av(B.o,!1,o)
j.$flags=3
i=$.F=new A.a7(j,$.bu(),192,20,23,7,16,1)
h=i}else h=i
i=i.a
k=k.a
if(!(k<i.length))return A.a(i,k)
k=i[k]
i=h}if(l===B.d)l=3e4
else{if(i==null){j=A.av(B.o,!1,o)
j.$flags=3
i=$.F=new A.a7(j,$.bu(),192,20,23,7,16,1)}i=i.a
l=l.a
if(!(l<i.length))return A.a(i,l)
l=i[l]}l=k>l&&c.aF(a,m)<0}else l=!1
if(l)continue
B.a.k(s,m)}if(s.length===0)return b}f=c.ad(a,s,null,-1)
for(r=-a0,q=a1-1,e=0;e<s.length;++e){A.cG(s,f,e)
if(!(e<s.length))return A.a(s,e)
a.X(s[e])
d=-c.bh(a,r,-b,q)
a.Y()
if(c.ax)return 0
if(d>=a0)return a0
if(d>b)b=d}return b},
bh(a,b,c,d){return this.aD(a,b,c,d,null)},
aF(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=b.b,d=a.a,c=e.a
if(!(c>=0&&c<8))return A.a(d,c)
c=d[c]
t=e.b
if(!(t>=0&&t<8))return A.a(c,t)
s=c[t]
if(s==null)return 0
c=b.a
t=c.a
if(!(t>=0&&t<8))return A.a(d,t)
t=d[t]
r=c.b
if(!(r>=0&&r<8))return A.a(t,r)
q=t[r]
if(q==null)return 0
t=s.a
if(t===B.d)t=3e4
else{r=$.F
r=(r==null?$.F=A.cp():r).a
t=t.a
if(!(t<r.length))return A.a(r,t)
t=r[t]}p=A.j([t],u.t)
t=u.v
o=A.h3([c],t)
n=q.a
m=a.b===B.c?B.e:B.c
for(c=u.S,l=0;;n=i){k=A.eo(a,e,m,o,A.fc())
if(k==null)break
r=k.a
if(!(r>=0&&r<8))return A.a(d,r)
r=d[r]
j=k.b
if(!(j>=0&&j<8))return A.a(r,j)
i=r[j].a
if(i===B.d){r=A.h2(t)
r.bn(0,o)
r.k(0,k)
if(A.eo(a,e,m===B.c?B.e:B.c,r,A.fc())!=null)break}++l
if(n===B.d)r=3e4
else{r=$.F
if(r==null){h=A.av(B.o,!1,c)
h.$flags=3
r=$.F=new A.a7(h,$.bu(),192,20,23,7,16,1)}r=r.a
j=n.a
if(!(j<r.length))return A.a(r,j)
j=r[j]
r=j}j=l-1
if(!(j<p.length))return A.a(p,j)
B.a.k(p,r-p[j])
o.k(0,k)
m=m===B.c?B.e:B.c}for(g=l;g>0;g=f){f=g-1
e=p.length
if(!(f<e))return A.a(p,f)
d=p[f]
if(!(g<e))return A.a(p,g)
B.a.i(p,f,-Math.max(-d,p[g]))}if(0>=p.length)return A.a(p,0)
return p[0]},
aE(a,b,c){var t,s,r,q,p,o,n,m,l
if(!this.w)return
t=b.a
s=t.a*8+t.b
t=b.b
r=t.a*8+t.b
t=this.f
t===$&&A.D()
q=a.a
if(!(q<2))return A.a(t,q)
p=t[q]
o=c*c
if(c<0)o=-o
if(!(s>=0&&s<64))return A.a(p,s)
t=p[s]
if(!(r>=0&&r<64))return A.a(t,r)
if(Math.abs(t[r]+o)>1048576)for(n=0;n<64;++n){m=p[n]
for(l=0;l<64;++l)B.a.i(m,l,B.b.K(m[l],1))}t=p[s]
B.a.i(t,r,t[r]+o)},
bk(a,b){var t,s,r=this.Q
r===$&&A.D()
t=r.length
if(a>=t)return
if(!(a<t))return A.a(r,a)
s=r[a]
if(J.an(s[0],b))return
s[1]=s[0]
B.a.i(s,0,b)},
a0(a,b){var t=A.fP(b,null)
return a===B.c?t:-t},
ad(a,b,c,d){var t,s,r,q,p
u.Q.a(b)
if(d>=0){t=this.Q
t===$&&A.D()
t=d<t.length}else t=!1
if(t){t=this.Q
t===$&&A.D()
if(!(d>=0&&d<t.length))return A.a(t,d)
s=t[d]}else s=B.aG
r=a.b
q=A.H(b.length,0,u.S)
for(p=0;p<b.length;++p)B.a.i(q,p,this.be(a,b[p],c,s,null,r))
return q},
be(a,b,c,d,e,f){var t,s,r,q,p,o,n,m
u.q.a(d)
if(b.v(0,c))return 1e6
t=b.b
s=a.a
r=t.a
if(!(r>=0&&r<8))return A.a(s,r)
q=s[r]
t=t.b
if(!(t>=0&&t<8))return A.a(q,t)
p=q[t]
if(p!=null){t=b.a
r=t.a
if(!(r>=0&&r<8))return A.a(s,r)
r=s[r]
t=t.b
if(!(t>=0&&t<8))return A.a(r,t)
o=r[t]
t=p.a
r=$.F
if(r==null){s=$.F=A.cp()
r=s}else s=r
s=s.a
t=t.a
if(!(t<s.length))return A.a(s,t)
n=s[t]
if(o==null)m=0
else{t=o.a
s=r.a
t=t.a
if(!(t<s.length))return A.a(s,t)
m=s[t]}if(m>n&&this.aF(a,b)<0)return-2e4+n*10-m
return 1e4+n*10-m}if(b.v(0,d[0]))return 9000
if(b.v(0,d[1]))return 8000
if(b.v(0,e))return 7500
if(!this.w)return 0
s=this.f
s===$&&A.D()
q=f.a
if(!(q<2))return A.a(s,q)
q=s[q]
s=b.a
s=s.a*8+s.b
if(!(s>=0&&s<64))return A.a(q,s)
s=q[s]
t=r*8+t
if(!(t<64))return A.a(s,t)
return B.b.aM(s[t],-7000,7000)}}
A.ck.prototype={}
A.t.prototype={
v(a,b){var t
if(b==null)return!1
if(this!==b)t=b instanceof A.t&&b.a===this.a&&b.b===this.b
else t=!0
return t},
gn(a){return this.a*8+this.b},
h(a){return A.x(97+this.a)+(this.b+1)}}
A.cJ.prototype={
aj(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=null
if(a.z!==3)return b
for(t=a.a,s=b,r=s,q=r,p=q,o=0,n=0;n<8;++n)for(m=0;m<8;++m){l=t[n][m]
if(l==null)continue
k=l.a
if(k===B.d)if(l.b===B.c){if(p!=null)return b
p=new A.t(n,m)}else{if(q!=null)return b
q=new A.t(n,m)}else if(k===B.i){if(s!=null)return b
r=l.b
s=new A.t(n,m)}else ++o}if(p==null||q==null||s==null||o>0)return b
t=p.a
k=p.b
j=s.a
i=s.b
h=q.a
g=q.b
t*=8
j*=8
h*=8
if(r===B.c){f=a.b===B.c?0:1
e=a.c
e=e?1:0
d=a.d
d=d?1:0
c=A.ez(t+k,j+i,h+g,f,e,d)
d=this.a
if(!(c>=0&&c<d.length))return A.a(d,c)
return d[c]}else{f=a.b===B.e?0:1
e=a.d
e=e?1:0
d=a.c
d=d?1:0
c=A.ez(h+g,j+i,t+k,f,e,d)
d=this.a
if(!(c>=0&&c<d.length))return A.a(d,c)
return d[c]}}}
A.b7.prototype={
a8(){return"ScoreType."+this.b}}
A.c9.prototype={}
A.cK.prototype={
aj(a){var t,s=this.b,r=a.R(0,A.cQ(this.a)).a3(0)
if(!(r>=0&&r<s.length))return A.a(s,r)
t=s[r]
if(t!=null){s=t.a.P(0,a)
s=s!==0}else s=!0
if(s)return null
return t}}
A.d7.prototype={
b0(){var t,s,r,q,p,o,n,m,l=this,k=new A.d0()
k.b_(1749277564)
t=new A.d8(k)
s=u.d
r=J.aP(12,s)
for(q=u.R,p=0;p<12;++p){o=A.j(new Array(64),q)
for(n=0;n<64;++n)o[n]=t.$0()
r[p]=o}u.V.a(r)
l.a!==$&&A.dT()
l.a=r
m=u.Y.a(t.$0())
l.b!==$&&A.dT()
l.b=m
q=s.a(A.j([t.$0(),t.$0()],q))
l.c!==$&&A.dT()
l.c=q}}
A.d8.prototype={
$0(){var t=4294967296,s=this.a,r=s.aQ(t),q=s.aQ(t)
return A.cQ(r).F(0,32).aT(0,A.cQ(q)).bG(0,64)},
$S:9}
A.di.prototype={
$1(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null,c="tablebase"
A.eX(a)
try{t=u.e.a(B.B.bt(A.a4(a.data),d))
if(J.an(J.M(t,"init"),!0)){n=A.dI(J.M(t,"book"))
n=A.hb(n==null?"":n)
this.a.a=A.ev(n,B.N,J.M(t,c)==null?d:new A.cJ(B.O.bs(A.a4(J.M(t,c)))))
return}s=A.fG()
for(n=u.j,m=n.a(J.M(t,"moves")),l=m.length,k=0;k<m.length;m.length===l||(0,A.dk)(m),++k){r=m[k]
q=n.a(r)
j=A.T(J.M(q,0))
i=A.T(J.M(q,1))
h=A.T(J.M(q,2))
g=A.T(J.M(q,3))
if(J.M(q,4)==null)f=d
else{f=A.T(J.M(q,4))
if(!(f>=0&&f<6))return A.a(B.r,f)
f=B.r[f]}s.X(new A.A(new A.t(j,i),new A.t(h,g),f))}n=this.a
m=n.a
n=m==null?n.a=A.ev(d,B.N,d):m
m=A.T(J.M(t,"depth"))
p=n.aU(s,A.e8(0,A.T(J.M(t,"budget"))),m)
o=p.a
m=v.G.self
if(o==null)n=d
else{n=o.a
l=o.a
j=o.b
i=o.b
h=o.c
h=h==null?d:h.a
h=A.j([n.a,l.b,j.a,i.b,h],u.c)
n=h}m.postMessage(B.B.bw(A.h0(["move",n,"score",p.b,"nodes",p.c],u.N,u.X),d))}catch(e){n=v.G.self
n.postMessage('{"move":null,"error":true}')}},
$S:10};(function aliases(){var t=J.a1.prototype
t.aZ=t.h})();(function installTearOffs(){var t=hunkHelpers._static_0,s=hunkHelpers._static_1
t(A,"im","hd",0)
s(A,"iw","i0",1)
s(A,"fc","hk",11)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.k,null)
r(A.k,[A.dp,J.bH,A.b6,J.ao,A.h,A.cH,A.d,A.au,A.C,A.af,A.aw,A.aL,A.a0,A.cL,A.cz,A.I,A.cu,A.bO,A.bP,A.aT,A.bh,A.cO,A.c7,A.d2,A.cU,A.d5,A.Q,A.cf,A.d3,A.az,A.cj,A.aC,A.m,A.bs,A.bC,A.cP,A.bA,A.cZ,A.n,A.bD,A.cW,A.c0,A.ba,A.cq,A.bG,A.ab,A.cI,A.aA,A.d0,A.co,A.cg,A.a7,A.A,A.cA,A.S,A.c5,A.b8,A.cF,A.ck,A.t,A.cJ,A.c9,A.cK,A.d7])
r(J.bH,[J.bJ,J.aR,J.aU,J.ar,J.as,J.aS,J.a9])
r(J.aU,[J.a1,J.i,A.aa,A.b0])
r(J.a1,[J.c1,J.aB,J.W])
s(J.bI,A.b6)
s(J.cr,J.i)
r(J.aS,[J.aQ,J.bK])
r(A.h,[A.at,A.bc,A.bL,A.cb,A.c4,A.ce,A.aV,A.bw,A.U,A.be,A.ca,A.bb,A.bB])
r(A.d,[A.aO,A.cc,A.cl])
r(A.aO,[A.Z,A.Y,A.aW])
r(A.Z,[A.b5,A.ci])
s(A.aD,A.af)
s(A.p,A.aD)
s(A.aE,A.aw)
s(A.bd,A.aE)
s(A.aM,A.bd)
s(A.aN,A.aL)
r(A.a0,[A.by,A.bz,A.c8,A.de,A.dg,A.cT,A.cy,A.di])
r(A.by,[A.cC,A.d8])
s(A.b3,A.bc)
r(A.c8,[A.c6,A.aq])
r(A.I,[A.X,A.ch])
r(A.bz,[A.df,A.cv,A.cx,A.d_,A.cS])
r(A.b0,[A.bT,A.ax])
r(A.ax,[A.bi,A.bk])
s(A.bj,A.bi)
s(A.aZ,A.bj)
s(A.bl,A.bk)
s(A.b_,A.bl)
r(A.aZ,[A.bU,A.bV])
r(A.b_,[A.bW,A.bX,A.bY,A.bZ,A.c_,A.b1,A.b2])
s(A.bn,A.ce)
s(A.bm,A.az)
s(A.ad,A.bm)
r(A.bC,[A.cn,A.ct,A.cs])
s(A.bN,A.aV)
s(A.bM,A.bA)
s(A.cY,A.cZ)
r(A.U,[A.ay,A.bF])
r(A.cW,[A.b9,A.E,A.b7])
t(A.bi,A.m)
t(A.bj,A.C)
t(A.bk,A.m)
t(A.bl,A.C)
t(A.aE,A.bs)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{b:"int",l:"double",al:"num",w:"String",da:"bool",ab:"Null",e:"List",k:"Object",O:"Map",r:"JSObject"},mangledNames:{},types:["b()","@(@)","~(k?,k?)","@(@,w)","@(w)","~(@,@)","b(b,b)","b(b)","~(b,b,E)","ap()","ab(r)","b(E)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.p&&a.b(c.a)&&b.b(c.b)}}
A.hO(v.typeUniverse,JSON.parse('{"W":"a1","c1":"a1","aB":"a1","j5":"aa","bJ":{"da":[],"f":[]},"aR":{"f":[]},"aU":{"r":[]},"a1":{"r":[]},"i":{"e":["1"],"r":[],"d":["1"]},"bI":{"b6":[]},"cr":{"i":["1"],"e":["1"],"r":[],"d":["1"]},"aS":{"l":[],"al":[]},"aQ":{"l":[],"b":[],"al":[],"f":[]},"bK":{"l":[],"al":[],"f":[]},"a9":{"w":[],"cB":[],"f":[]},"at":{"h":[]},"aO":{"d":["1"]},"Z":{"d":["1"]},"b5":{"Z":["1"],"d":["1"],"Z.E":"1"},"p":{"aD":[],"af":[]},"aM":{"bd":["1","2"],"aE":["1","2"],"aw":["1","2"],"bs":["1","2"],"O":["1","2"]},"aL":{"O":["1","2"]},"aN":{"aL":["1","2"],"O":["1","2"]},"b3":{"h":[]},"bL":{"h":[]},"cb":{"h":[]},"a0":{"a8":[]},"by":{"a8":[]},"bz":{"a8":[]},"c8":{"a8":[]},"c6":{"a8":[]},"aq":{"a8":[]},"c4":{"h":[]},"X":{"I":["1","2"],"ek":["1","2"],"O":["1","2"],"I.K":"1","I.V":"2"},"Y":{"d":["1"]},"aW":{"d":["1"]},"aD":{"af":[]},"aT":{"hi":[],"cB":[]},"bh":{"cE":[],"bQ":[]},"cc":{"d":["cE"]},"c7":{"bQ":[]},"cl":{"d":["bQ"]},"aa":{"r":[],"f":[]},"b0":{"r":[]},"bT":{"r":[],"f":[]},"ax":{"G":["1"],"r":[]},"aZ":{"m":["l"],"e":["l"],"G":["l"],"r":[],"d":["l"],"C":["l"]},"b_":{"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"]},"bU":{"m":["l"],"e":["l"],"G":["l"],"r":[],"d":["l"],"C":["l"],"f":[],"m.E":"l"},"bV":{"m":["l"],"e":["l"],"G":["l"],"r":[],"d":["l"],"C":["l"],"f":[],"m.E":"l"},"bW":{"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"bX":{"dm":[],"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"bY":{"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"bZ":{"dw":[],"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"c_":{"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"b1":{"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"b2":{"dx":[],"m":["b"],"e":["b"],"G":["b"],"r":[],"d":["b"],"C":["b"],"f":[],"m.E":"b"},"ce":{"h":[]},"bn":{"h":[]},"ad":{"az":["1"],"el":["1"],"d":["1"]},"I":{"O":["1","2"]},"aw":{"O":["1","2"]},"bd":{"aE":["1","2"],"aw":["1","2"],"bs":["1","2"],"O":["1","2"]},"az":{"d":["1"]},"bm":{"az":["1"],"d":["1"]},"ch":{"I":["w","@"],"O":["w","@"],"I.K":"w","I.V":"@"},"ci":{"Z":["w"],"d":["w"],"Z.E":"w"},"aV":{"h":[]},"bN":{"h":[]},"bM":{"bA":["k?","w"]},"l":{"al":[]},"b":{"al":[]},"e":{"d":["1"]},"cE":{"bQ":[]},"w":{"cB":[]},"n":{"ap":[]},"bw":{"h":[]},"bc":{"h":[]},"U":{"h":[]},"ay":{"h":[]},"bF":{"h":[]},"be":{"h":[]},"ca":{"h":[]},"bb":{"h":[]},"bB":{"h":[]},"c0":{"h":[]},"ba":{"h":[]},"bG":{"h":[]},"aA":{"hl":[]},"fT":{"e":["b"],"d":["b"]},"dx":{"e":["b"],"d":["b"]},"hn":{"e":["b"],"d":["b"]},"fS":{"e":["b"],"d":["b"]},"dw":{"e":["b"],"d":["b"]},"dm":{"e":["b"],"d":["b"]},"hm":{"e":["b"],"d":["b"]},"fQ":{"e":["l"],"d":["l"]},"fR":{"e":["l"],"d":["l"]}}'))
A.hN(v.typeUniverse,JSON.parse('{"aO":1,"ax":1,"bm":1,"bC":2}'))
var u=(function rtii(){var t=A.cm
return{Y:t("ap"),C:t("h"),Z:t("a8"),U:t("d<@>"),R:t("i<ap>"),p:t("i<e<b>>"),_:t("i<A>"),D:t("i<E>"),n:t("i<+(b,b)>"),s:t("i<w>"),G:t("i<cg>"),b:t("i<@>"),t:t("i<b>"),o:t("i<A?>"),B:t("i<t?>"),c:t("i<b?>"),T:t("aR"),m:t("r"),g:t("W"),J:t("G<@>"),d:t("e<ap>"),V:t("e<e<ap>>"),M:t("e<e<e<b>>>"),f:t("e<e<b>>"),A:t("e<e<A?>>"),Q:t("e<A>"),j:t("e<@>"),q:t("e<A?>"),l:t("e<S?>"),e:t("O<w,@>"),W:t("O<@,@>"),O:t("A"),P:t("ab"),K:t("k"),a:t("E"),L:t("j6"),F:t("+()"),h:t("cE"),r:t("b5<w>"),v:t("t"),N:t("w"),k:t("f"),w:t("aB"),x:t("n"),y:t("da"),i:t("l"),S:t("b"),bc:t("ed<ab>?"),z:t("r?"),aL:t("e<@>?"),ab:t("A?"),X:t("k?"),aD:t("S?"),dd:t("w?"),E:t("c9?"),c8:t("cj?"),u:t("da?"),I:t("l?"),a3:t("b?"),ae:t("al?"),H:t("al"),cQ:t("~(w,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.X=J.bH.prototype
B.a=J.i.prototype
B.b=J.aQ.prototype
B.q=J.aS.prototype
B.f=J.a9.prototype
B.Y=J.W.prototype
B.Z=J.aU.prototype
B.aU=A.b2.prototype
B.E=J.c1.prototype
B.y=J.aB.prototype
B.O=new A.cn()
B.P=new A.bG()
B.z=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.Q=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.V=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.R=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.U=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.T=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.S=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.A=function(hooks) { return hooks; }

B.B=new A.bM()
B.W=new A.c0()
B.l=new A.cH()
B.a_=new A.cs(null)
B.a0=new A.ct(null)
B.H=new A.p(1,0)
B.K=new A.p(-1,0)
B.F=new A.p(0,1)
B.G=new A.p(0,-1)
B.v=t([B.H,B.K,B.F,B.G],u.n)
B.an=t([-38,-28,-18,-18,-16,-18,-28,-38],u.t)
B.as=t([-28,-18,-8,-3,-3,-8,-2,-12],u.t)
B.az=t([-18,-3,2,7,7,2,-3,-18],u.t)
B.a1=t([-18,-3,7,12,12,7,-3,-18],u.t)
B.aP=t([-18,-3,7,12,12,7,-3,-3],u.t)
B.aK=t([-2,-3,2,20,9,2,-3,-16],u.t)
B.av=t([-28,-18,8,-3,13,-5,-18,-12],u.t)
B.aD=t([-28,-12,-2,-2,-8,-14,-12,-38],u.t)
B.a3=t([B.an,B.as,B.az,B.a1,B.aP,B.aK,B.av,B.aD],u.p)
B.i=new A.E("R",4,"rook")
B.k=new A.E("N",3,"knight")
B.j=new A.E("E",2,"elephant")
B.d=new A.E("K",0,"king")
B.p=new A.E("C",1,"counsellor")
B.m=t([B.i,B.k,B.j,B.d,B.p,B.j,B.k,B.i],u.D)
B.h=new A.E("P",5,"pawn")
B.r=t([B.d,B.p,B.j,B.k,B.i,B.h],u.D)
B.C=t([0,140,90,55,30,15,5],u.t)
B.b_=new A.p(2,2)
B.b1=new A.p(2,-2)
B.b5=new A.p(-2,2)
B.b7=new A.p(-2,-2)
B.w=t([B.b_,B.b1,B.b5,B.b7],u.n)
B.a4=t([-20,-10,-18,-10,-10,-18,-10,-20],u.t)
B.al=t([-18,0,5,2,2,5,0,-18],u.t)
B.a5=t([-18,5,10,2,2,10,5,-18],u.t)
B.aM=t([-10,2,2,15,15,2,2,-10],u.t)
B.aR=t([-10,10,2,15,15,2,2,-10],u.t)
B.aC=t([-18,5,10,2,2,10,5,-5],u.t)
B.a7=t([-10,0,5,2,18,5,0,-17],u.t)
B.ac=t([-20,-18,-8,-10,-10,-2,-18,-20],u.t)
B.aa=t([B.a4,B.al,B.a5,B.aM,B.aR,B.aC,B.a7,B.ac],u.p)
B.n=t([B.i,B.k,B.j,B.p,B.d,B.j,B.k,B.i],u.D)
B.c=new A.b9(0,"white")
B.e=new A.b9(1,"black")
B.ao=t([B.c,B.e],A.cm("i<b9>"))
B.M=new A.p(-1,-1)
B.L=new A.p(-1,1)
B.J=new A.p(1,-1)
B.I=new A.p(1,1)
B.t=t([B.M,B.K,B.L,B.G,B.F,B.J,B.H,B.I],u.n)
B.x=t([B.I,B.J,B.L,B.M],u.n)
B.aO=t([-8,-8,-3,2,2,-3,-8,-1],u.t)
B.ar=t([-3,2,2,2,2,2,2,13],u.t)
B.af=t([-13,8,-8,-8,-8,-8,-8,-13],u.t)
B.aw=t([-13,-8,-8,-8,-8,-8,8,-13],u.t)
B.aL=t([-13,-6,-8,7,8,-8,-8,2],u.t)
B.a2=t([-3,-8,8,8,8,8,-8,3],u.t)
B.aj=t([3,8,8,8,-8,8,8,3],u.t)
B.ay=t([7,7,8,13,13,8,8,-8],u.t)
B.aq=t([B.aO,B.ar,B.af,B.aw,B.aL,B.a2,B.aj,B.ay],u.p)
B.aX=new A.p(1,2)
B.aY=new A.p(1,-2)
B.b2=new A.p(-1,2)
B.b3=new A.p(-1,-2)
B.aZ=new A.p(2,1)
B.b0=new A.p(2,-1)
B.b4=new A.p(-2,1)
B.b6=new A.p(-2,-1)
B.u=t([B.aX,B.aY,B.b2,B.b3,B.aZ,B.b0,B.b4,B.b6],u.n)
B.D=t([0,0,0,0,0,0,0,0],u.t)
B.a9=t([52,52,42,32,32,42,52,68],u.t)
B.aB=t([17,22,12,7,7,12,25,27],u.t)
B.aN=t([15,7,2,2,2,2,12,18],u.t)
B.ab=t([13,-3,2,12,12,2,-3,-3],u.t)
B.aI=t([-5,0,-3,7,7,-3,-1,3],u.t)
B.aQ=t([-8,-8,-8,-8,-8,-8,-8,-8],u.t)
B.ax=t([B.D,B.a9,B.aB,B.aN,B.ab,B.aI,B.aQ,B.D],u.p)
B.aE=t([-1,1],u.t)
B.aG=t([null,null],u.o)
B.a6=t([-22,-32,-32,-58,-58,-48,-32,-22],u.t)
B.a8=t([-22,-32,-48,-58,-42,-32,-48,-22],u.t)
B.aS=t([-22,-32,-48,-46,-42,-32,-32,-22],u.t)
B.au=t([-22,-48,-32,-42,-58,-32,-32,-38],u.t)
B.ag=t([-12,-22,-22,-32,-32,-22,-22,-12],u.t)
B.aJ=t([-2,-12,-12,-12,-12,-12,-12,-2],u.t)
B.aA=t([28,28,8,8,8,8,28,28],u.t)
B.ah=t([28,22,16,-8,-8,2,22,28],u.t)
B.aH=t([B.a6,B.a8,B.aS,B.au,B.ag,B.aJ,B.aA,B.ah],u.p)
B.o=t([0,142,192,292,492,92],u.b)
B.aF=t([-20,-10,-18,-18,-6,-2,-10,-28],u.t)
B.ae=t([-10,-8,-8,-8,5,-6,-8,-18],u.t)
B.ai=t([-2,-8,-3,5,18,13,-8,-2],u.t)
B.am=t([-2,-3,-3,7,7,13,-3,-18],u.t)
B.ap=t([-2,-8,2,7,7,8,-8,-15],u.t)
B.ad=t([-2,10,2,2,2,18,2,-2],u.t)
B.ak=t([-2,-3,8,-8,-8,-8,13,-2],u.t)
B.at=t([-28,-2,-18,-4,-18,-2,-18,-20],u.t)
B.aT=t([B.aF,B.ae,B.ai,B.am,B.ap,B.ad,B.ak,B.at],u.p)
B.aV=new A.S(B.h,B.c)
B.aW=new A.S(B.h,B.e)
B.b8=new A.b7(0,"exact")
B.b9=new A.b7(1,"lowerBound")
B.ba=new A.b7(2,"upperBound")
B.bn=new A.c5(!1)
B.N=new A.c5(!0)
B.bb=A.R("iU")
B.bc=A.R("iV")
B.bd=A.R("fQ")
B.be=A.R("fR")
B.bf=A.R("fS")
B.bg=A.R("dm")
B.bh=A.R("fT")
B.bi=A.R("k")
B.bj=A.R("dw")
B.bk=A.R("hm")
B.bl=A.R("hn")
B.bm=A.R("dx")})();(function staticFields(){$.cX=null
$.K=A.j([],A.cm("i<k>"))
$.eq=null
$.cD=0
$.dt=A.im()
$.e5=null
$.e4=null
$.f8=null
$.f5=null
$.fb=null
$.dc=null
$.dh=null
$.dQ=null
$.d1=A.j([],A.cm("i<e<k>?>"))
$.eE=null
$.eF=null
$.eG=null
$.eH=null
$.dy=A.cV("_lastQuoRemDigits")
$.dz=A.cV("_lastQuoRemUsed")
$.bg=A.cV("_lastRemUsed")
$.dA=A.cV("_lastRem_nsh")
$.F=null})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal,s=hunkHelpers.lazy
t($,"iX","ff",()=>A.f7("_$dart_dartClosure"))
t($,"iW","dU",()=>A.f7("_$dart_dartClosure_dartJSInterop"))
t($,"ju","fz",()=>A.j([new J.bI()],A.cm("i<b6>")))
t($,"j8","fk",()=>A.a_(A.cM({
toString:function(){return"$receiver$"}})))
t($,"j9","fl",()=>A.a_(A.cM({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"ja","fm",()=>A.a_(A.cM(null)))
t($,"jb","fn",()=>A.a_(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
t($,"je","fq",()=>A.a_(A.cM(void 0)))
t($,"jf","fr",()=>A.a_(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
t($,"jd","fp",()=>A.a_(A.eA(null)))
t($,"jc","fo",()=>A.a_(function(){try{null.$method$}catch(r){return r.message}}()))
t($,"jh","ft",()=>A.a_(A.eA(void 0)))
t($,"jg","fs",()=>A.a_(function(){try{(void 0).$method$}catch(r){return r.message}}()))
t($,"jj","fv",()=>new Int8Array(A.i2(A.j([-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-1,-2,-2,-2,-2,-2,62,-2,62,-2,63,52,53,54,55,56,57,58,59,60,61,-2,-2,-2,-1,-2,-2,-2,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-2,-2,-2,-2,63,-2,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-2,-2,-2,-2,-2],u.t))))
t($,"ji","fu",()=>A.ep(0))
t($,"jq","B",()=>A.ac(0))
t($,"jo","L",()=>A.ac(1))
t($,"jp","fy",()=>A.ac(2))
t($,"jm","e0",()=>$.L().E(0))
t($,"jk","e_",()=>A.ac(1e4))
s($,"jn","fx",()=>A.et("^\\s*([+-]?)((0x[a-f0-9]+)|(\\d+)|([a-z0-9]+))\\s*$",!1))
t($,"jl","fw",()=>A.ep(8))
t($,"jt","dl",()=>A.f9(B.bi))
t($,"j7","dZ",()=>{A.he()
return $.cD})
t($,"js","bu",()=>A.dr([B.aH,B.aT,B.aa,B.a3,B.aq,B.ax],u.f))
t($,"j1","fi",()=>A.H(8,0,u.S))
t($,"iY","fg",()=>A.H(8,0,u.S))
t($,"j2","fj",()=>A.H(8,-1,u.S))
t($,"iZ","fh",()=>A.H(8,8,u.S))
t($,"j3","dX",()=>A.H(16,0,u.S))
t($,"j_","dV",()=>A.H(16,0,u.S))
t($,"j4","dY",()=>A.H(16,0,u.S))
t($,"j0","dW",()=>A.H(16,0,u.S))
t($,"jr","a5",()=>A.hR())})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.aa,SharedArrayBuffer:A.aa,ArrayBufferView:A.b0,DataView:A.bT,Float32Array:A.bU,Float64Array:A.bV,Int16Array:A.bW,Int32Array:A.bX,Int8Array:A.bY,Uint16Array:A.bZ,Uint32Array:A.c_,Uint8ClampedArray:A.b1,CanvasPixelArray:A.b1,Uint8Array:A.b2})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.ax.$nativeSuperclassTag="ArrayBufferView"
A.bi.$nativeSuperclassTag="ArrayBufferView"
A.bj.$nativeSuperclassTag="ArrayBufferView"
A.aZ.$nativeSuperclassTag="ArrayBufferView"
A.bk.$nativeSuperclassTag="ArrayBufferView"
A.bl.$nativeSuperclassTag="ArrayBufferView"
A.b_.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.iN
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()