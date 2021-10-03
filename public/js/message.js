function dojQueryAjax() {
    $(function(){
    var chat = '/chatupdate/' + $('.sendtalkroom').text();
    console.log(chat);
    // jQueryのajaxメソッドを使用しajax通信
    $.ajax({
        type: "GET", // Getメソッドで通信
 
        url: chat, // 取得先のURL
 
        cache: false, // キャッシュしないで読み込み
 
        // 通信成功時に呼び出されるコールバック
        success: function (data) {
 
            $('#ajaxreload').html(data);
 
        },
        // 通信エラー時に呼び出されるコールバック
        error: function () {
 
            alert("Ajax通信エラー");
 
 
        }
    });
    });
 
}
 
window.addEventListener('load', function () {
 
    setTimeout(dojQueryAjax, 1000);
 
});

/*$('.fa-paper-plane').on('click', function() {
    $(function(){
    var id = $('.sendtalkroom').text();
    var send = '/chat/' + $('.sendtalkroom').text();
    console.log(send);
    
    if (send != '/chat/'){
        var comment = $('.fa-paper-plane').text();
        // jQueryのajaxメソッドを使用しajax通信
        $.ajax({
            
            type: "POST", // Getメソッドで通信
 
            url: send, // 取得先のURL
 
            data: {
                talkroom_id: id,
                comment: comment
            },
        
            datatype: "json",
        
            cache: false, // キャッシュしないで読み込み
 
            // 通信成功時に呼び出されるコールバック
            success: function (data) {

                $('#ajaxreload').html(data);
 
            },
            // 通信エラー時に呼び出されるコールバック
            error: function () {
 
            alert("Ajax通信エラー");
 
 
            }
            });
    }
    });
});*/
