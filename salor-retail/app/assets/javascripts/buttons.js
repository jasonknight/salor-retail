function makeSortable(id) {
  return $('#' + id).sortable({
    dropOnEmpty: false,
    cursor: 'crosshair',
    items: 'div.item-button',
    opacity: 0.4,
    scroll: true,
    update: function() {
      return $.ajax({
        type: 'post',
        data: $('#' + id).sortable('serialize'),
        dataType: 'script',
        url: '/buttons/position'
      });
    }
  });
};