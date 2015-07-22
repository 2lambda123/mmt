var go_to_form = function(form,value) {
  // TODO switch to goToForm()

  $("#new_form_name").val(value);

  // Handle any JS validation and related issues for @content_partial_name
  //   Call page specific JS validations & handle findings
  // If ready, go to server to take next appropriate action
  // document.forms["edit_draft_<%= @draft_id %>"].submit();

  form.submit();
}


$(document).ready(function() {
  $('.add-another-field').click(function() {
    var type = getFieldType(this);

    var fields = $('.'+ type +'-fields').find('select, input');
    if (fields.is(":visible")) {
      // if fields are visible

      // get last index used by previous values
      var lastIndex = 0;
      if ($('.'+ type +'-values input').length > 0) {
        var id = $('.'+ type +'-values input').last().attr('id').replace( /[^\d.]/g, '' );
        lastIndex = parseInt(id);
      }


      // Display field values with other organization values
      var values = getKeyValuePairs(fields);
      $('.'+ type +'-values').append(values);

      $.each(fields, function(index, field) {
        var id = $(field).attr('id');
        var name = $(field).attr('name');

        // Create a hidden field with each fields value
        var newField = $('<input>');
        $(newField).attr('type', 'hidden');
        $(newField).attr('name', name.replace("index", lastIndex+1));
        $(newField).attr('id', id.replace("index", lastIndex+1));
        $(newField).attr('value', $(field).val());
        $('.'+ type +'-values').append(newField);

        // Clear field
        $(field).val('');
      });
    } else {
      // if fields are not visible
      // show the form and done button
      $('.'+ type +'-fields').show();
      $('.cancel-add.'+ type +'').show();

      // Enable fields
      $(fields).removeAttr('disabled');
    }
  });

  // Hide form, and remove required fields
  $('.cancel-add').click(function() {
    var type = getFieldType(this);

    var fields = $('.'+ type +'-fields').find('select, input');

    // Disable fields to keep from being submitted
    $(fields).attr('disabled', true);

    // Hide form
    $('.'+ type +'-fields').hide();

    // Hide 'Done' button
    $(this).hide();
  });

  var getFieldType = function(field) {
    var classes = $(field).attr('class').split(/\s+/)
    var type = '';
    if (classes.indexOf('organization') != -1) {
      type = 'organization';
    } else if (classes.indexOf('related-url') != -1) {
      type = 'related-url'
    }
    return type;
  }

  var getKeyValuePairs = function(fields) {
    console.log('getting pairs');
    var values = [];
    $.each(fields, function(index, field) {
      var label = $('label[for="'+ $(field).attr('id') +'"]').text();
      var value = '';
      switch (field.type) {
        case "text":
          console.log('text field');
          value = $(field).val();
          break;
        case "select-one":
          console.log('select field');
          value = $(field).find("option:selected").text();
          break;
        default:

      }
      if (value != '') {
        values.push(label + ": " + value);
      }
    });

    return "<p>" + values.join(" | ") + "</p>";;
  }
});
