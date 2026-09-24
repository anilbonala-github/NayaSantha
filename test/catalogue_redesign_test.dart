import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naya_santha/features/catalogue/presentation/catalogue_screen.dart';
import 'package:naya_santha/features/catalogue/presentation/catalogue_providers.dart';
import 'package:naya_santha/features/catalogue/presentation/product_detail_screen.dart';
import 'package:naya_santha/features/catalogue/domain/catalogue_models.dart';
import 'package:naya_santha/features/basket/presentation/basket_providers.dart';
import 'package:naya_santha/features/basket/domain/basket_models.dart';
import 'package:naya_santha/features/admin/admin_screen.dart';
import 'package:naya_santha/core/theme/app_theme.dart';

class EmptyBasket extends BasketNotifier {
 @override Future<Basket> build() async=>const Basket(id:'basket',status:'ACTIVE',itemCount:0,estimatedTotal:0,maximumPayable:0,items:[]);
}
const carrot=Product(id:'carrot',name:'Fresh carrots',categoryId:'vegetables',unit:'500 g',sellingPrice:39,description:'Fresh carrots. Store in the refrigerator.',origin:'Telangana');
void main(){
 for(final width in [320.0,1200.0]){
  testWidgets('catalogue opens dynamic product details at width $width',(tester)async{
   tester.view.physicalSize=Size(width,900);tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
   final router=GoRouter(initialLocation:'/categories',routes:[
    GoRoute(path:'/categories',builder:(_,__)=>const Scaffold(body:CatalogueScreen())),
    GoRoute(path:'/product/:id',builder:(_,s)=>ProductDetailScreen(productId:s.pathParameters['id']!)),
   ]);addTearDown(router.dispose);
   await tester.pumpWidget(ProviderScope(overrides:[basketProvider.overrideWith(EmptyBasket.new),categoriesProvider.overrideWith((ref)async=>[const Category(id:'vegetables',name:'Vegetables',slug:'vegetables')]),productsProvider.overrideWith((ref,q)async=>const ProductPage(items:[carrot],page:0,totalPages:1,totalElements:1)),productProvider.overrideWith((ref,id)async=>carrot)],child:MaterialApp.router(theme:AppTheme.light(),routerConfig:router)));
   await tester.pumpAndSettle();expect(find.text('Shop groceries'),findsOneWidget);expect(find.text('Fresh carrots'),findsOneWidget);expect(tester.takeException(),isNull);
   await tester.tap(find.text('Fresh carrots'));await tester.pumpAndSettle();expect(find.text('Product details'),findsOneWidget);expect(find.text('Fresh carrots. Store in the refrigerator.'),findsOneWidget);expect(find.textContaining('max ₹'),findsNothing);expect(tester.takeException(),isNull);
  });
 }
 testWidgets('product editor validates required fields before save',(tester)async{
  await tester.pumpWidget(ProviderScope(child:MaterialApp(theme:AppTheme.light(),home:Scaffold(body:Builder(builder:(context)=>TextButton(onPressed:()=>showDialog(context:context,builder:(_)=>const ProductEditor(categories:[{'id':'vegetables','name':'Vegetables'}])),child:const Text('Edit')))))));
  await tester.tap(find.text('Edit'));await tester.pumpAndSettle();await tester.tap(find.text('Save product'));await tester.pumpAndSettle();expect(find.text('Required'),findsWidgets);expect(tester.takeException(),isNull);
 });
}
