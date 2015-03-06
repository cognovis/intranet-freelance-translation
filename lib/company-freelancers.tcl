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
        distinct on(f.user_id) user_id, 
        im_name_from_user_id(user_id, 1) as name,
        to_char(start_date, 'YYYY-MM-DD') as last_task_assignment,
        (select member_state from cc_users where user_id = f.user_id) as status,
    	(select 
    		count(*)
	from 
	 	im_projects p, 
		im_companies c,
		acs_rels r
	where 
	 	p.company_id = c.company_id
		and c.company_id = :company_id
	 	and r.rel_type = 'im_biz_object_member'
		and r.object_id_two = f.user_id
		and r.object_id_one = p.project_id
		and p.parent_id is null
	 ) as number_of_projects
    from (
	select 
	  	r.object_id_two as user_id,
		p.start_date
	from 
		im_projects p, 
		im_companies c,
		acs_rels r
	where 
		p.company_id = c.company_id
		and c.company_id = :company_id
		and r.rel_type = 'im_biz_object_member'
		and r.object_id_two in (select member_id from group_distinct_member_map m where group_id = '465')
		and r.object_id_one = p.project_id
        order by
            r.object_id_two
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
    append tr "<tr class='roweven'>"
    append tr "        <td><a href=\"/intranet/users/view?user_id=$user_id\">$name</a></td>"
    append tr "	       <td>$last_task_assignment</td>"
    append tr "	       <td align='center'>$number_of_projects</td>"
    append tr "	       <td>$status</td></tr>"
    append tr "</tr>"
    incr ctr
}

if { "" != $tr } {
    set html_output "<table cellpadding='3' cellspacing='3' border='0'>\n
	<tr>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-core.Name "Name"]</td>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-translation-freelance.LastAssignment "Last Assignment"]</td>\n
		<td class='rowtitle'>[lang::message::lookup "" intranet-translation-freelance.NumberOfProjects "Number <br>of Projects"]</td>\n
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
