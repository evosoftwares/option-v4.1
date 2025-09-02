import 'package:flutter_test/flutter_test.dart';
import 'package:option/controllers/driver_stepper_controller.dart';
import 'package:option/utils/supabase_helper.dart';

void main() {
  group('Teste de Validação Visual de Veículos', () {
    late DriverStepperController controller;

    setUpAll(() {
      // Marcar Supabase como inicializado para testes
      SupabaseHelper.markInitialized();
    });

    setUp(() {
      controller = DriverStepperController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Campos iniciais não devem mostrar erro até serem tocados', () {
      // Estado inicial - nenhum campo foi tocado
      expect(controller.brandFieldTouched, false);
      expect(controller.modelFieldTouched, false);
      expect(controller.yearFieldTouched, false);
      expect(controller.plateFieldTouched, false);
      expect(controller.colorFieldTouched, false);

      // Não deve haver erros se não foram tocados
      expect(controller.brandHasError, false);
      expect(controller.modelHasError, false);
      expect(controller.yearHasError, false);
      expect(controller.plateHasError, false);
      expect(controller.colorHasError, false);

      // Mensagens de erro devem ser null
      expect(controller.brandErrorMessage, null);
      expect(controller.modelErrorMessage, null);
      expect(controller.yearErrorMessage, null);
      expect(controller.plateErrorMessage, null);
      expect(controller.colorErrorMessage, null);
    });

    test('Campos devem mostrar erro quando tocados mas vazios', () {
      // Simular que o usuário tocou em cada campo mas deixou vazio
      controller.setBrand('');
      controller.setModel('');
      controller.setYear('');
      controller.setPlate('');
      controller.setColor('');

      // Agora os campos foram tocados
      expect(controller.brandFieldTouched, true);
      expect(controller.modelFieldTouched, true);
      expect(controller.yearFieldTouched, true);
      expect(controller.plateFieldTouched, true);
      expect(controller.colorFieldTouched, true);

      // E devem mostrar erro
      expect(controller.brandHasError, true);
      expect(controller.modelHasError, true);
      expect(controller.yearHasError, true);
      expect(controller.plateHasError, true);
      expect(controller.colorHasError, true);

      // Com mensagens de erro apropriadas
      expect(controller.brandErrorMessage, 'Selecione uma marca');
      expect(controller.modelErrorMessage, 'Selecione um modelo');
      expect(controller.yearErrorMessage, 'Informe o ano');
      expect(controller.plateErrorMessage, 'Informe a placa');
      expect(controller.colorErrorMessage, 'Informe a cor');
    });

    test('Campos devem limpar erro quando preenchidos', () {
      // Primeiro, marcar campos como tocados e vazios (com erro)
      controller.setBrand('');
      expect(controller.brandHasError, true);

      // Depois preencher o campo
      controller.setBrand('Honda');
      expect(controller.brandHasError, false);
      expect(controller.brandErrorMessage, null);

      // Mesmo para outros campos
      controller.setYear('');
      expect(controller.yearHasError, true);
      
      controller.setYear('2020');
      expect(controller.yearHasError, false);
      expect(controller.yearErrorMessage, null);
    });

    test('validateVehicleFields deve marcar todos os campos como tocados', () {
      // Estado inicial
      expect(controller.brandFieldTouched, false);
      expect(controller.modelFieldTouched, false);
      expect(controller.yearFieldTouched, false);
      expect(controller.plateFieldTouched, false);
      expect(controller.colorFieldTouched, false);

      // Chamar validação
      controller.validateVehicleFields();

      // Todos os campos devem estar marcados como tocados
      expect(controller.brandFieldTouched, true);
      expect(controller.modelFieldTouched, true);
      expect(controller.yearFieldTouched, true);
      expect(controller.plateFieldTouched, true);
      expect(controller.colorFieldTouched, true);

      // E como estão vazios, devem mostrar erro
      expect(controller.brandHasError, true);
      expect(controller.modelHasError, true);
      expect(controller.yearHasError, true);
      expect(controller.plateHasError, true);
      expect(controller.colorHasError, true);
    });

    test('Campos preenchidos não devem mostrar erro', () {
      // Preencher todos os campos
      controller.setBrand('Honda');
      controller.setModel('Civic');
      controller.setYear('2020');
      controller.setPlate('ABC1234');
      controller.setColor('Branco');

      // Campos foram tocados mas não devem ter erro
      expect(controller.brandFieldTouched, true);
      expect(controller.modelFieldTouched, true);
      expect(controller.yearFieldTouched, true);
      expect(controller.plateFieldTouched, true);
      expect(controller.colorFieldTouched, true);

      expect(controller.brandHasError, false);
      expect(controller.modelHasError, false);
      expect(controller.yearHasError, false);
      expect(controller.plateHasError, false);
      expect(controller.colorHasError, false);

      // E deve poder prosseguir
      expect(controller.canProceedFromVehicle, true);
    });
  });
}