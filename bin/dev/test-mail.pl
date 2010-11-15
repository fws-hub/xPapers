use xPapers::Conf;
use xPapers::Mail::Message;

xPapers::Mail::MessageMng->notifyAdmin("test mail: " . localtime(), content=>"test");

