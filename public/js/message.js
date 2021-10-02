function dojQueryAjax() {
    
    var chat = document.getElementsByClassName('sendtalkroom').text;
    console.log(chat);
    // jQueryのajaxメソッドを使用しajax通信
    $.ajax({
        type: "GET", // Getメソッドで通信
 
        url: "/chatupdate/chat", // 取得先のURL
 
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
 
window.addEventListener('load', function () {
 
    setTimeout(dojQueryAjax, 1000);
 
});