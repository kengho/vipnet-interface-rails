$(document).ready(function() {
  $('input[type=radio]').change(function() {
    $(this).closest("form").submit();
  });
});
