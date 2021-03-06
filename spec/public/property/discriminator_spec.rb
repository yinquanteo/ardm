require 'spec_helper'

module ::DiscBlog
  class Content < Ardm::Record
    self.table_name = "articles"

    property :id,    Serial
    property :title, String, :required => true
    property :type,  Discriminator, :field => "slug"
    timestamps :at
  end

  class Article < Content; end
  class Announcement < Article; end
  class Release < Announcement; end
end


describe Ardm::Property::Discriminator do
  before do
    @content_model      = DiscBlog::Content
    @article_model      = DiscBlog::Article
    @announcement_model = DiscBlog::Announcement
    @release_model      = DiscBlog::Release
  end

  describe '.options' do
    subject { described_class.options }

    it { is_expected.to be_kind_of(Hash) }

    it { is_expected.to include(:load_as => Class, :required => true) }
  end

  it 'should typecast to a Model' do
    expect(@article_model.properties[:type].typecast('DiscBlog::Release')).to equal(@release_model)
  end

  describe 'Model#new' do
    describe 'when provided a String discriminator in the attributes' do
      before do
        @resource = @article_model.new(:type => 'DiscBlog::Release')
      end

      it 'should return a Resource' do
        expect(@resource).to be_kind_of(Ardm::Record)
      end

      it 'should be an descendant instance' do
        expect(@resource).to be_instance_of(DiscBlog::Release)
      end
    end

    describe 'when provided a Class discriminator in the attributes' do
      before do
        @resource = @article_model.new(:type => DiscBlog::Release)
      end

      it 'should return a Resource' do
        expect(@resource).to be_kind_of(Ardm::Record)
      end

      it 'should be an descendant instance' do
        expect(@resource).to be_instance_of(DiscBlog::Release)
      end
    end

    describe 'when not provided a discriminator in the attributes' do
      before do
        @resource = @article_model.new
      end

      it 'should return a Resource' do
        expect(@resource).to be_kind_of(Ardm::Record)
      end

      it 'should be a base model instance' do
        expect(@resource).to be_instance_of(@article_model)
      end
    end
  end

  describe 'Model#descendants' do
    it 'should set the descendants for the grandparent model' do
      expect(@article_model.descendants.to_a).to match_array([ @announcement_model, @release_model ])
    end

    it 'should set the descendants for the parent model' do
      expect(@announcement_model.descendants.to_a).to eq([ @release_model ])
    end

    it 'should set the descendants for the child model' do
      expect(@release_model.descendants.to_a).to eq([])
    end
  end

  describe 'Model#default_scope', :pending => "I don't understand the intention of these" do
    it 'should have no default scope for the top level model' do
      expect(@content_model.default_scope[:type]).to be_nil
    end

    it 'should set the default scope for the grandparent model' do
      expect(@article_model.default_scope[:type].to_a).to match_array([ @article_model, @announcement_model, @release_model ])
    end

    it 'should set the default scope for the parent model' do
      expect(@announcement_model.default_scope[:type].to_a).to match_array([ @announcement_model, @release_model ])
    end

    it 'should set the default scope for the child model' do
      expect(@release_model.default_scope[:type].to_a).to eq([ @release_model ])
    end
  end

  before do
    @announcement = @announcement_model.create(:title => 'Announcement')
  end

  it 'should persist the type' do
    expect(@announcement.class.find(*@announcement.key).type).to equal(@announcement_model)
  end

  it 'should be retrieved as an instance of the correct class' do
    expect(@announcement.class.find(*@announcement.key)).to be_instance_of(@announcement_model)
  end

  it 'should include descendants in finders' do
    expect(@article_model.first).to eql(@announcement)
  end

  it 'should not include ancestors' do
    expect(@release_model.first).to be_nil
  end
end
