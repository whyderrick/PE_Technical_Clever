$(document).ready(function() {
  // This is called after the document has loaded in its entirety
  // This guarantees that any elements we bind to will exist on the page
  // when we try to bind to them

  // See: http://docs.jquery.com/Tutorials:Introducing_$(document).ready()

  showProfile();
});

function showProfile(){
  if($('.profile-container').length > 0) {
    $.ajax({
      url: '/clever_login',
      method: 'get',
    })
    .done(function(msg){
      $('.profile-container').empty();
      $('.profile-container').append(msg);
    })
  }
}
