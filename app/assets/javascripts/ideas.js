$(document).ready(function(){
	// if an organization progress needs to be translated,
	// get the text to be translated and put it in the link
	$('.translate_org_progress').each(function(index){
		id = $(this).attr('data-id');
		// get the text
		text = encodeURIComponent($('#org_progress_' + id).text());

		// update the url with this text
		$(this).attr('href', $(this).attr('href').replace(gon.placeholder, text));

	});


	if (gon.edit_idea_progress){
		// load the date time pickers
		$('#idea_progress_progress_date').datepicker({
				dateFormat: 'dd.mm.yy',
		});
		if (gon.progress_date !== undefined && gon.progress_date.length > 0)
		{
			$("#idea_progress_progress_date").datepicker("setDate", new Date(gon.progress_date));
		}

		// if record is completed, show url field by default
		if ($('select#idea_progress_idea_status_id').val() === gon.idea_status_id_published) {
			$('#idea_progress_url_input').show();
		}

		// if progress is marked as completed, show news url field
		$("select#idea_progress_idea_status_id").change(function(){
			if ($(this).val() === gon.idea_status_id_published){
				// show url textbox
				$('#idea_progress_url_input').show(300);
			} else {
				// clear and hide url textbox
				$('#idea_progress_url').attr('value', '');
				$('#idea_progress_url_input').hide(300);
			}
		});
	}


  // when ideas search form submitted, stop form and make it link request
  $('form#ideas_form_search').submit(function(){
    window.location.href = updateQueryStringParameter($('form#ideas_form_search').attr('action'), 'q', $('form#ideas_form_search input#q').val());
    return false;
  });






  $('#new_idea_inappropriate_report input[type="radio"]').change(function ()
  {
    $(this).parent().siblings('input').hide();
    $('#new_idea_inappropriate_report input[type="radio"]:checked').parent().next('input').show().focus();
  });


});
