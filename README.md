# 基于skynet的通用服务器
  方便多个项目一起维护，支持sock,web,websock
# 项目结构
```
3rd(第三方库,非必要)
common(通用模块,本库)
    luaclib(编译好的c库)
    lualib-src(c库源码)
    lualib(lua库)
    service(通用服务)
skynet(fork skynet项目，不作任何改动)
test(项目例子,https://github.com/zhandouxiaojiji/test.git)
    sample
proj(你的项目)
    xxgame
    oogame
```
# 配置
```
mkdir workspace
cd workspace
git clone https://github.com/zhandouxiaojiji/common.git
git clone https://github.com/zhandouxiaojiji/skynet.git
git clone https://github.com/zhandouxiaojiji/test.git
mkdir proj #项目目录，参考test
cd skynet && make linux
cd ..
cd test/sample/shell
sh etc.sh game gamed #生成启动配置, etc.sh [配置名] [启动脚本] [是否以进程的方式启动]
./start.sh game #启动进程, start.sh [配置名]
```
# 脚本与库检索优先级
```
项目>common>skynet
这三个目录下都有luaclib,lualib-src,lualib,service这几个目录，skynet的所有代码不作改动，通用的写到common
脚本放到项目下script
```
