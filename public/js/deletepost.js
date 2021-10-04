$(document).on('click','.fa-trash' ,function() {
    
    console.log("出てこいや");
    var clickindex = $('.fa-trash').index(this);
    console.log(clickindex);
    
    $(".postnumber").each(function(index, element){
        console.log(index);
        console.log($(element).text());
        
        if(index == clickindex){
           var recruit = '/delete/' + $(element).text();
    
            console.log(recruit);
    
            if (recruit != '/delete/'){
        
                // jQueryのajaxメソッドを使用しajax通信
            $.ajax({
            
                type: "POST", // Getメソッドで通信
 
                url: recruit, // 取得先のURL
            
                cache: false, // キャッシュしないで読み込み
 
                // 通信成功時に呼び出されるコールバック
                success: function (data) {
    
                    $('#postreload').html(data);
 
                },
                // 通信エラー時に呼び出されるコールバック
                error: function () {
 
                alert("Ajax通信エラー");
 
 
                }
            });
        
            }
        }
    });
    
});
