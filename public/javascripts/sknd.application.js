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

  // Podcasts#show / Reviews#list
  $("body.podcast.show h2.linkable").click(function(){
    $("#s_episodes").toggle();
  });
});

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

