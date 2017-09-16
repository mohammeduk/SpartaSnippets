$(function() {
  setInterval(function () {
    console.log("changing")
    $.get( "/api/v1/snippets/rand", function (data) {
      $("#question").text(data.question)
      $("#answer").text(data.answer)
      console.log(data);
    });
  }, 15000);
});

function launchFullScreen(element) {
  // var x = document.getElementById('play-link');
  //   x.style.display = 'none';
  // var x = document.getElementById('manage-link');
  //   x.style.display = 'none';

    if(element.requestFullScreen) {
      element.requestFullScreen();
    } else if(element.mozRequestFullScreen) {
      element.mozRequestFullScreen();
    } else if(element.webkitRequestFullScreen) {
      element.webkitRequestFullScreen();
    }
    $('.navbar').slideUp();
    $('#play-link').slideUp();
  }

  // $("#play-link").click(function(){
  //     $("#play-link").hide(1000);
  //     $("#play-h1").hide(1000);
  //     $("#manage-link").hide(1000);
  //     $("#play-h3").hide(1000);
  // });


  $('#play-link').click(function (element) {
        launchFullScreen(document.documentElement);
    });

    $(document).bind('webkitfullscreenchange mozfullscreenchange fullscreenchange', function(e) {
        var state = document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen;
        var event = state ? 'FullscreenOn' : 'FullscreenOff';

        if(event == 'FullscreenOff') {
            $('.navbar').slideDown();
            $('#play-link').slideDown();
        }
    });
