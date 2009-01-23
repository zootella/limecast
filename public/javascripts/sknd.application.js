$(document).ready(function() {
  $(".audio_player .url").map(function(){
    var flashvars = {
      soundFile: $(this).attr('href')
    };

    var movie = $("<span />").flash({
      src:       "/flash/player.swf",
      width:     290,
      height:    24,
      flashvars: flashvars
    });

    $(this).parent().append(movie);

    return false;
  });

  $(".audio_player").hover(function(){
		$(this).find("a.popup").show();
  }, function(){
		$(this).find("a.popup").hide();
	});

  // Episodes/Reviews toggle links
  $(".supplemental h2.linkable a").click(function(){
    $(".supplemental h2.linkable.current").removeClass('current');
    $(this).parent().addClass('current');
    $(this).addClass('current');

    $("#s_episodes_wrap").toggle();
    $("#s_reviews_wrap").toggle();
  });
  
  $(".supplemental #r_view .linkable a").click(function(){
    $(".supplemental #r_view .linkable.current").removeClass('current');
    $(this).parent('span.linkable').addClass('current');

    if ($(this).attr('rel') == 'all') $("#s_reviews .review").show();
    else if ($(this).attr('rel') == 'positive') {
      $("#s_reviews .review.negative").hide();
      $("#s_reviews .review.positive").show();
    } else if ($(this).attr('rel') == 'negative') {
      $("#s_reviews .review.negative").show();
      $("#s_reviews .review.positive").hide();
    }
    
    return false;
  });
});

/*
$.fn.extend({
  dropdown: function(opts){
    var me = $(this);
		opts.click = opts.click || function(){};

    var update_text = function(){
      me.find('> a').text( selected_text() );
    };

		var selected_text = function(){
      return me.find('ul li.selected a').text();
    };

		var selected_data = function(){
		  var data = me.find('ul li.selected span').text();

			if(data != "")
			  return data;
  		else
				return selected_text();
		};

    me.find('ul li a').click(function(){
      me.find('ul li').removeClass('selected');
      $(this).parent().addClass('selected');
      update_text();

			opts.click( selected_data() );
    });

    me.find('> a').click(function(){
      me.find("div").toggle();
    });

    update_text();

    return me;
  }
});

$(document).ready(function(){
  $('.dropdown').map(function(){
    $(this).dropdown({
      click: function(data){
	  	  alert(data);
      }
    });
  });
});
*/
$(document).ready(function(){
  $("#episode_sort_container").fdd2div({OpenStatus:1, GenerateHyperlinks:0});
});

