import 'package:flutter_test/flutter_test.dart';
import 'package:naya_santha/core/api/api_failure.dart';
import 'package:naya_santha/features/auth/data/msg91_mobile_otp.dart';

void main() {
  test('send, cooldown, default-channel retry and verification use one request', () async {
    var now = DateTime(2026, 9, 25);
    final sent = <Map<String, dynamic>>[], retries = <Map<String, dynamic>>[], checked = <Map<String, dynamic>>[];
    final otp = Msg91MobileOtp(clock: () => now,
      send: (body) async { sent.add(body); return {'type':'success','message':'request-1'}; },
      retry: (body) async { retries.add(body); return {'type':'success','message':'sent'}; },
      verify: (body) async { checked.add(body); return {'type':'success','message':'header.payload.signature'}; });
    await otp.send('9121304215');
    expect(sent.single['identifier'],'919121304215');
    await expectLater(otp.send('9121304215'),throwsA(isA<ApiFailure>()));
    now = now.add(const Duration(seconds:31));
    await otp.send('9121304215');
    expect(retries.single, {'reqId':'request-1'});
    await expectLater(otp.verify('9704214215','123456'),throwsA(isA<ApiFailure>()));
    expect(checked,isEmpty);
    expect(await otp.verify('9121304215','123456'),'header.payload.signature');
    expect(checked.single,{'reqId':'request-1','otp':'123456'});
    await expectLater(otp.verify('9121304215','123456'),throwsA(isA<ApiFailure>()));
  });
  test('failed send does not create a challenge or expose provider errors', () async {
    final otp=Msg91MobileOtp(send: (_) async => throw Exception('private provider response'));
    await expectLater(otp.send('9121304215'),throwsA(isA<ApiFailure>().having((e)=>e.userMessage,'safe message',isNot(contains('private')))));
    await expectLater(otp.verify('9121304215','123456'),throwsA(isA<ApiFailure>()));
  });
  test('resend limit stops a third resend', () async {
    var now=DateTime(2026,9,25);
    var retryCount=0;
    final otp=Msg91MobileOtp(clock:()=>now,
      send: (_) async => {'type':'success','message':'request'},
      retry: (_) async {retryCount++;return {'type':'success'};});
    await otp.send('9121304215');
    for(var i=0;i<2;i++){now=now.add(const Duration(seconds:31));await otp.send('9121304215');}
    now=now.add(const Duration(seconds:31));
    await expectLater(otp.send('9121304215'),throwsA(isA<ApiFailure>()));
    expect(retryCount,2);
  });
}
