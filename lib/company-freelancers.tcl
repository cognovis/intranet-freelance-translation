ad_page_contract {
    company-freelancers.tcl
}

set user_id [ad_maybe_redirect_for_registration]

# Check permissions. "See details" is an additional check for
# critical information

im_company_permissions $user_id $company_id view read write admin

if { !$read } { return "" }

set sql "

select * from (
    select 
        distinct on(user_id) user_id, 
        im_name_from_user_id(user_id, 1) as name,
        to_char(creation_date, 'YYYY-MM-DD') as last_task_assignment,
        (select member_state from cc_users where user_id = f.user_id) as status
    from (
        select 
            u.user_id,
            o.creation_date
        from 
            im_trans_tasks tt, 
            im_companies c, 
            im_projects p,
            users u,
            acs_objects o
        where 
            tt.project_id = p.project_id 
            and c.company_id = p.company_id
            and c.company_id = :company_id
            and o.object_id = tt.task_id
            and (
                   tt.trans_id = u.user_id OR 
                   tt.edit_id = u.user_id OR
                   tt.proof_id = u.user_id OR
                   tt.other_id = u.user_id)
            and u.user_id in (select member_id from group_distinct_member_map m where group_id = '465')
        order by 
            u.user_id
        ) f
) g 

order by 
	last_task_assignment DESC 
limit 50
"

set tr ""
set html_output ""
set ctr 0

db_foreach r $sql {
    append tr "<tr class='roweven'><td>$name</td><td>$last_task_assignment</td><td>$status</td></tr>"
    incr ctr
}

if { "" != $tr } {
    set html_output "<table cellpadding='3' cellspacing='3' border='0'>\n
	<tr>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-core.Name "Name"]</td>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-translation-freelance.LastAssignment "Last Assignment"]</td>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-translation-freelance.UserStatus "Status"]</td>\n
	</tr>
	$tr\n
	</table>"
    if { $ctr > 50 } {
	append html_output "<br>[lang::message::lookup "" intranet-translation-freelance.LimitedTo50 "Only 50 freelancers are shown but found more"]"
    }
} else {
    set html_output  [lang::message::lookup "" intranet-translation-freelance.NoFreelancersFound "No Freelancers worked for this client so far"]
}
