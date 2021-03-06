{* DO NOT EDIT THIS FILE! Use an override template instead. *}
{default attribute_base='ContentObjectAttribute'}
{let attribute_content=$attribute.content}

{def $vid_d=hash('response', array(hash('description', '', 'title', '', 'tags', '')))}

<div id="botr_vid_at_{$attribute.id}" class='botr_wrapper'>

{* Current image. *}

<div class="block">
<label>Current Total Video Platform Usage:</label>
<div class="current-usage"><span>{$attribute_content.attributes.delivery}</span><div>Delivered this Month</div></div>
<div class="current-usage"><span>{$attribute_content.attributes.storage}</span><div>Total Stored</div></div>
<label>Current Video:</label>
<div class='fileDetails'>

{section show=$attribute_content}
{set $vid_d = $attribute_content.attributes}

{$vid_d.html}
{section-else}
<p>There is no video file</p>
{/section}
</div>
{section show=$attribute_content}
<input class="removebutton button" type="button" value="Remove video" onclick="$(this).attr('class', 'removebutton button-disabled').attr('disabled', 'disabled').parent().find('.fileDetails').html('<p>There is no video file</p>')"/>
{section-else}
<input class="removebutton button-disabled" type="button" value="Remove video" disabled="disabled" />
{/section}
</div>

<input id="ezcoa-{if ne( $attribute_base, 'ContentObjectAttribute' )}{$attribute_base}-{/if}{$attribute.contentclassattribute_id}_{$attribute.contentclass_attribute_identifier}" class="savemarker {eq( $html_class, 'half' )|choose( 'box', 'halfbox' )} ezcc-{$attribute.object.content_class.identifier} ezcca-{$attribute.object.content_class.identifier}_{$attribute.contentclass_attribute_identifier}" type="hidden" name="{$attribute_base}_ezstring_data_text_{$attribute.id}" value="{$attribute.data_text|wash( xhtml )}" />

{* New video file for upload. *}



<div class='pre_upload'>
	<label>Video Title</label>
	<input class='box' type="text" name="title" value="{$vid_d.response.0.video.title}"/>
	<label>Description</label>
	<textarea class='box' name="description" >{$vid_d.response.0.video.description}</textarea>
	<label>Tags</label>
	<input class='box tags' type="text" name="tags" value="{$vid_d.response.0.video.tags}"/>
	<input type="hidden" name="date" value='{currentdate()|datetime('custom', '%m/%d/%Y')}'/>
	<input type="hidden" name="author" value='{fetch(user, current_user).contentobject.name}'/>
	<input type="hidden" name="redirect_uri" value='/botr_video_dt/post_url'/>
</div>
<div class='fake_uploadForm'>
	<label>Select video</label>
	<input id="fake_uploadFile_{$attribute.id}" class='box fake_uploadFile' type="file" name="file" />
</div>
<small class="uploadText">You can upload any video format (WMV, AVI, MP4, MOV, FLV, ...)</small>
<input type='button' onclick="getvidposturl('botr_vid_at_{$attribute.id}'); return false;" class="uploadButton" value='Upload'>

</div>

{run-once}

    {ezscript_require( array( 'botr.upload.dt.js', 'jquery.uploadProgress.js', 'jquery.urlEncode.js' )  )}

	{literal}
	<script>
		
	var botr_active_at_id = 0;
	var botr_active_key = 0;
	var getviddatatimer = null;
	var cur_bot_file = null;
	
	jQuery(".uploadButton").removeAttr("disabled");
		
	function botr_upload_success(frame) {
		try {
		state = jQuery(frame).contents().find('xmp').html();
		} catch(e) {
			alert("BOTR Error - unsupported media type.");
			jQuery(".uploadBar").css('display','none');
			jQuery(".uploadButton").removeAttr("disabled");
			jQuery(".uploadProgress").css('width', '0px');
			return false;
		}
		if (state == '') state = "{}";
		up_res = eval("(" + jQuery.URLDecode(state) + ")");
		jQuery(".uploadBar").css('display','none');
		jQuery(".uploadButton").removeAttr("disabled");
		jQuery(".uploadProgress").css('width', '0px');
		jQuery(".uploadText.active").html("You can upload any video format (WMV, AVI, MP4, MOV, FLV, ...)").removeClass('active');
		if (up_res == null || up_res.video_key == undefined) {
			jQuery("#" + botr_active_at_id + " .fileDetails").html("<p>Upload error! Please try again.</p>");
			return false;
		}
		jQuery("#" + botr_active_at_id + " .fileDetails").html(up_res.html);
		jQuery("#" + botr_active_at_id + " .savemarker").val(up_res.video_key);
		jQuery("#" + botr_active_at_id + " .removebutton").removeAttr("disabled").attr('class', 'removebutton button');
		clearInterval(getviddatatimer);
		botr_active_key = up_res.video_key;
		getviddatatimer = setInterval ( "getviddata()", 5000 )
	}
	
	function getviddata() {
		jQuery.get('/botr_video_dt/post_url?video_key=' + botr_active_key, function(data) {
			up_res = eval("(" + jQuery.URLDecode(data.replace(/<\/?xmp>/gm,'')) + ")");
			if (up_res.conversion != '') {
				jQuery("#" + botr_active_at_id + " .fileDetails").html(up_res.html);
				clearInterval(getviddatatimer);
			}
		});
	}
		
	jQuery(function(){
		if (!jQuery("#uploadFormFrame").length) {
			botrf = jQuery("<div></div>").attr('id', 'uploadFormFrame').css({"position":"absolute", "left":"-10000px"});
			jQuery("body").append(botrf);
		}
	})

	function getvidposturl(at_id){
		botr_active_at_id = at_id;
		try
		  {
			jQuery.post("/botr_video_dt/create_url", jQuery('#' + at_id + ' .pre_upload input, #' + at_id + ' .pre_upload textarea').serialize().replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0'), function(data){
				var real = jQuery("#" + at_id + " .fake_uploadFile");
				cur_bot_file = real.val();
				if (data.indexOf('http:') == 0 && real.val()) {
					at_id = botr_active_at_id;
					jQuery("#uploadFormFrame").empty();
					form_html = '<fo'+'rm method="POST" target="BOTRTARGET" id="uploadForm" enctype="multipart/form-data"><input id="uploadToken" name="token" value=""/></form>';
					jQuery("#uploadFormFrame").html(form_html);
					var cloned = jQuery('<input class="box fake_uploadFile" type="file" name="file" />'); 
					goform = jQuery("#uploadForm");
					goform.attr('action', data);
					real.appendTo(goform);
					jQuery("#uploadToken").val(data.split("token=")[1]);
					botr_add_upoload_progress(at_id);
					goform.submit();
					cloned.insertAfter(real).attr('id', 'fake_uploadFile_{/literal}{$attribute.id}{literal}');  

				} else {
					alert('Please complete all fields before submitting!')
				}
			});	

		  }
		catch(err)
		  {
		  alert(err);
		  }
		return false;
	}
	</script>
	{/literal}
	
	<iframe name="BOTRTARGET" style='visibility: hidden; position: absolute' onload="botr_upload_success(this)">
	</iframe>

{/run-once}

{/let}
{/default}