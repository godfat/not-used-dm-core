require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe DataMapper::Model do
  before :all do
    module ::Blog
      class Article
        include DataMapper::Resource

        property :id,      Serial
        property :title,   String, :nullable => false
        property :content, Text
        property :author,  String, :nullable => false

        belongs_to :original, :model => self, :nullable => true
        has n, :revisions, :model => self, :child_key => [ :original_id ]
        has 1, :previous,  :model => self, :child_key => [ :original_id ], :order => [ :id.desc ]
      end
    end

    @article_model = Blog::Article
  end

  supported_by :all do
    before :all do
      @author = 'Dan Kubb'

      @original = @article_model.create(:title => 'Original Article',                                               :author => @author)
      @article  = @article_model.create(:title => 'Sample Article',   :content => 'Sample', :original => @original, :author => @author)
      @other    = @article_model.create(:title => 'Other Article',    :content => 'Other',                          :author => @author)
    end

    it { @article_model.should respond_to(:copy) }

    describe '#override!' do
      before :each do
        @model = @article_model.dup # prevend side effect
      end

      it 'should raise an exception when attemping override an internal method' do
        lambda{
          @model.send(:define_method, :reset, &lambda{})
        }.should(raise_error(DataMapper::ReservedError))
      end

      it 'should just override the internal method if #override! is called' do
        msg = 'this is overrided'
        @model.override!(:reload)
        @model.send(:define_method, :reload, &lambda{msg})
        @model.new.reload.should == msg
      end
    end

    describe '#copy' do
      with_alternate_adapter do
        describe 'between identical models' do
          before :all do
            @return = @resources = @article_model.copy(@repository.name, @alternate_adapter.name)
          end

          it 'should return an Enumerable' do
            @return.should be_a_kind_of(Enumerable)
          end

          it 'should return Resources' do
            @return.each { |r| r.should be_a_kind_of(DataMapper::Resource) }
          end

          it 'should have each Resource set to the expected Repository' do
            @resources.each { |r| r.repository.name.should == @alternate_adapter.name }
          end

          it 'should create the Resources in the expected Repository' do
            @article_model.all(:repository => DataMapper.repository(@alternate_adapter.name)).should == @resources
          end
        end

        describe 'between different models' do
          before :all do
            # make sure the default repository is empty
            @article_model.all(:repository => @repository).destroy!

            # add an extra property to the alternate model
            DataMapper.repository(@alternate_adapter.name) do
              @article_model.property :status, String, :default => 'new'
            end

            if @article_model.respond_to?(:auto_migrate!)
              @article_model.auto_migrate!(@alternate_adapter.name)
            end

            # add new resources to the alternate repository
            DataMapper.repository(@alternate_adapter.name) do
              @heff1 = @article_model.create(:title => 'Alternate Repository', :author => @author)
            end

            # copy from the alternate to the default repository
            @return = @resources = @article_model.copy(@alternate_adapter.name, :default)
          end

          it 'should return an Enumerable' do
            @return.should be_a_kind_of(Enumerable)
          end

          it 'should return Resources' do
            @return.each { |r| r.should be_a_kind_of(DataMapper::Resource) }
          end

          it 'should have each Resource set to the expected Repository' do
            @resources.each { |r| r.repository.name.should == :default }
          end

          it 'should create the Resources in the expected Repository' do
            @article_model.all.should == @resources
          end
        end
      end
    end
  end
end
