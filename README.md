# 基于skynet的通用服务器 #
  方便多个项目一起维护
# 项目结构 #
Root
>3rd(第三方库)
>common(通用模块,本库)
>>luaclib(编译好的c库)
>>lualib-src(c库源码)
>>lualib(lua库)
>>service(通用服务)
>skynet(fork skynet项目，不作任何改动)
>test(项目例子,https://github.com/zhandouxiaojiji/test.git)
>>sample
>proj(你的项目)
>>xxgame
>>oogame
