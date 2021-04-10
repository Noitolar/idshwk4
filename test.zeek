@load base/frameworks/sumstats

event http_reply(c: connection, version: string, code: count, reason: string)
{
	SumStats::observe
	(
		$id="RES-CODE", 
		$orig_key=SumStats::Key($host=c$id$orig_h), 
		$obs=SumStats::Observation($num=1)
	);
	if (code == 404)
	{
		SumStats::observe
		(
			$id="404", 
			$orig_key=SumStats::Key($host=c$id$orig_h), 
			$obs=SumStats::Observation($num=1)
		);
		SumStats::observe
		(
			$id="404-URI", 
			$orig_key=SumStats::Key($host=c$id$orig_h), 
			$obs=SumStats::Observation($str=c$http$uri)
		);
	}
}

event init()
{
	local reducer_res_code_sum = SumStats::Reducer
	(
		$stream="RES-CODE", 
		$apply=set(SumStats::SUM)
	);
		
	local reducer_404_sum = SumStats::Reducer
	(
		$stream="404", 
		$apply=set(SumStats::SUM)
	);
	
	local reducer_404_unique = SumStats::Reducer
	(
		$stream="404-URI", 
		$apply=set(SumStats::UNIQUE)
	);
	
	SumStats::create([
		$name="IDSHWK_04_RESULT", 
		$epoch=10mins, 
		$reducers=set
		(
			reducer_res_code_sum, 
			reducer_404_sum, 
			reducer_404_unique
		),
		$epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result)=
		{
			local result_res_code_sum = result["RES-CODE"];
			local result_404_sum = result["404"];
			local result_404_unique = result["404-URI"];
			if (result_404_sum$sum > 2)
			{
				if (result_404_sum$sum/result_res_code_sum$sum > 0.2)
				{
					if (result_404_unique$unique/result_404_sum$sum > 0.5)
					{
						print fmt(" %s is a scanner with %.0f scan attemps on %d urls", key$host, result_404_sum$sum, result_404_unique$unique);
					}
				}
			}
		}
	]);
}
