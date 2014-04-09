--EE!
with block_info as
(	
select wtBlocked.wait_type, wtBlocked.wait_duration_ms, wtBlocked.resource_description, wtBlocked.session_id, wtBlocked.blocking_session_id, blockedText.text as BlockedQueryText, blockingText.text as BlockingQueryText
	,reqBlocked.open_transaction_count as OpenTransactions
	from sys.dm_os_waiting_tasks wtBlocked
	left outer join sys.dm_os_waiting_tasks wtBlocking on wtBlocked.blocking_session_id = wtBlocking.session_id
	join sys.dm_exec_requests reqBlocked on wtBlocked.session_id = reqBlocked.session_id
	left outer join sys.dm_exec_requests reqBlocking on wtBlocking.session_id = reqBlocking.session_id
	outer apply sys.dm_exec_sql_text(reqBlocked.sql_handle) blockedText
	outer apply sys.dm_exec_sql_text(reqBlocking.sql_handle) blockingText
)

select NULL wait_type, NULL wait_duration_ms, NULL resource_description, sess.session_id session_id, NULL blocking_session_id, COALESCE(blocking.Text, 'I ONLY BLOCK, I AM NOT BLOCKED') blocked_query_text, NULL blocking_query_text, sess.open_transaction_count from sys.dm_exec_sessions sess
--select * from sys.dm_exec_sessions sess
	left outer join sys.dm_exec_requests req on req.session_id = sess.session_id
	outer apply sys.dm_exec_sql_text(req.sql_handle) as blocking
	where sess.session_id in (select blocking_session_id from block_info)
		and sess.session_id not in (select session_id from block_info)
union all 
select * from block_info
