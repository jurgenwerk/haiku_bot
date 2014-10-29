$ ->
  $('.action-publish').click (e) ->
    e.preventDefault()
    haikuId = $(e.currentTarget).data('id')

    $.ajax(
      url: "/haikus/#{haikuId}"
      data: { id: haikuId }
      context: this
      type: "PUT"
    ).done =>
      $(e.currentTarget.parentElement.parentElement).fadeOut()
