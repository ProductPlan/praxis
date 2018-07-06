require 'spec_helper'

describe Praxis::MiddlewareApp do

  let(:init_args){ { root: 'here'} }
  let(:middleware) { Praxis::MiddlewareApp.for( init_args ) }
  let(:instance){ middleware.new(target)}

  context '.for' do
    it 'does not initialize the Application instance yet' do
      expect( Praxis::Application.instance ).to_not receive(:setup)
      middleware
    end
    it 'returns its class' do
      expect( middleware ).to be < Praxis::MiddlewareApp 
    end
  end

  context 'instantiated' do
    subject{ instance }
    let(:target_response){ [201,{}] }
    let(:target){ double("target app", call: target_response) }
    it 'saves the target app' do
      expect(subject.target).to be(target)
    end
    it 'does not initialize the Application instance yet' do
      expect( Praxis::Application.instance ).to_not receive(:setup)
      subject
    end
    
    context '.call' do
      let(:the_instance) { double("The instance") }
      let(:env){ {} }
      let(:praxis_response){ [200,{}] }
      subject(:response){ instance.call(env) }
      before do
        # always invokes the praxis app
        expect( Praxis::Application ).to receive(:new).once.and_return(the_instance)
        expect( the_instance ).to receive(:call).with( env ).once.and_return(praxis_response)
        allow( the_instance ).to receive(:setup).and_return(the_instance)
      end

      it 'initializes the application singletone with the passed parameters' do
        expect( the_instance ).to receive(:setup).with( init_args ).once
        subject
      end
      
      context 'properly handled (non-404 and 405) responses from praxis' do
        it 'are returned straight through' do
          expect( response ).to be(praxis_response)
        end
      end

      context '404/405 responses with X-Cascade = pass' do
        let(:praxis_response){ [404, {'X-Cascade' => 'pass'}]}
        it 'are forwarded to the target app' do
          expect( response ).to be(target_response)
        end
      end

      context '404/405 responses without X-Cascade = pass' do
        let(:praxis_response){ [404, {}]}
        it 'returned straight through' do
          expect( response ).to be(praxis_response)
        end
      end
    end
  end
end
