# ZEEK 第二次笔记

## 作业任务

使用zeek脚本完成以下功能：

* 根据404的出现模式来判断当前是否存在攻击者的扫描行为
* 404的出现原因可能有多种
  * 人类用户错误访问：404数量少
  * 爬虫：404数量多但是404占总响应的比例少
  * 失效的自动请求：404数量多且占响应的比例较高，但是主要针对同一个URL
  * 恶意扫描：404数量多且占响应的比例很高，针对不同URL

* 判定标准：
  * 每十分钟统计一次
  * 如果404响应数量 > 2则判定为机器
  * 如果404占总响应的20%以上则判定为非爬虫
  * 如果针对不同URL的404相应数量占所有404的50%以上则判定为恶意扫描

* 输出：( 扫描者ip ) is a scanner with ( 404总数 ) scan attempts on ( 不同404的数量 ) urls

## 功能强大的阴间模块: SUMSTATS

Summary-Statistics 用于统计的zeek模块

### 调用方式

```
@load base/frameworks/sumstats
```

### 基本语法

#### 构建统计 - observe()

使用SUMSTATS构建对于某个东西的统计有三个步骤：

* 建立一个观测对象(取个名字)
* key: 基于什么进行统计(对统计的东西进行分类的标准)
* value: 想要统计的具体东西

```
SumStats::observe($id="dns.lookup", $orig_key=SumStats::Key($host=c$id$orig_h), $obs=SumStats::Observation($str=query));
# 观测对象命名为"dns.lookup"
# 统计分类依据是连接的源ip地址
# 统计的具体对象是dns域名(在报文中以query呈现)
```

#### 统计计算 - Reducer()

对统计的结果进行分析计算

* 需要计算的观测对象名称
* 计算动作(sum, topk(旗下value最多的key是什么), last(最少的), average, max, min, unique...)

```
local reducer_01 = SumStats::Reducer($stream="dns.lookup", $apply=set(SumStats::UNIQUE));
# 对观察对象的dns.lookup进行计算
# 使用方法unique
# apply参数可以使用set的方式传入多个方法，例如$apply=set(SumStats::TOPK, SunStats::Average);
```

#### 开始统计 - create()

静态地构建好observe和reducer之后开始运行统计脚本：

* 观测对象名称
* 多长时间统计一轮
* reducer集合
* 传出参数：统计结果

```
SumStats::create([
	$name="dns.lookup.result",
	$epoch=6hrs,
	$reducers=set(reducer_01),
	$epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) = 
	{
		local result_01 = result["dns.lookup"];
		print fmt("6小时内 %s 一共进行了 %d 次针对 %d 个不同域名的dns查询", key$host, result_01$num, result_01$unique);
	}
]);
```

