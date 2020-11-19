## mailex

2020.11.17 可以正常发送 465 ssl 邮件，之前有两点，需要注意：
  1. idSMTP1.UseTLS := utUseImplicitTLS;
  2. idSMTP1.password := authCode;

