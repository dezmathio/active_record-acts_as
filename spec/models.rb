require_relative 'database_helper'

require 'active_record/acts_as'

class Product < ActiveRecord::Base
  actable
  belongs_to :store, touch: true
  has_many :buyers, dependent: :destroy
  has_one :payment, as: :payable
  validates_presence_of :name, :price
  store :settings, accessors: [:global_option]

  def present
    "#{name} - $#{price}"
  end

  def raise_error
    specific.non_existant_method
  end
end

class BaseUser < ActiveRecord::Base
  self.table_name = 'user'
  actable as: :user, class_name: 'BaseUser'
end

class WeddingUser < ActiveRecord::Base
  self.table_name = 'user_wedding'
  acts_as :base_user, as: :user, class_name: 'BaseUser'
  belongs_to :wedding, touch: true
end

class Wedding < ActiveRecord::Base
  self.table_name = 'wedding'
  has_many :wedding_users
end

class Payment < ActiveRecord::Base
  belongs_to :payable, polymorphic: true
end

class PenCollection < ActiveRecord::Base
  has_many :pens
end

class Pen < ActiveRecord::Base
  acts_as :product
  store_accessor :settings, :option1

  has_many :pen_caps, dependent: :destroy
  belongs_to :pen_collection, touch: true

  validates_presence_of :color
end

class Buyer < ActiveRecord::Base
  belongs_to :product
end

class PenCap < ActiveRecord::Base
  belongs_to :pen
end

class IsolatedPen < ActiveRecord::Base
  self.table_name = :pens
  acts_as :product, validates_actable: false
  store_accessor :settings, :option2

  validates_presence_of :color
end

class Store < ActiveRecord::Base
  has_many :products
end

module Inventory
  class ProductFeature < ActiveRecord::Base
    self.table_name = 'inventory_product_features'
    actable
    validates_presence_of :name, :price

    def present
      "#{name} - $#{price}"
    end
  end

  class PenLid < ActiveRecord::Base
    self.table_name = 'inventory_pen_lids'
    acts_as :product_feature, class_name: 'Inventory::ProductFeature'

    validates_presence_of :color
  end
end

def initialize_schema
  initialize_database do
    create_table :user, primary_key: 'user_id' do |t|
      t.boolean :active_flag, default: false
      t.string :user_type
      t.timestamps null: true
    end

    create_table :user_wedding, primary_key: 'user_id'  do |t|
      t.integer :wedding_id, foreign_key: true
      t.string :email
    end

    add_foreign_key "user_wedding", "user", primary_key: "user_id", name: "FK_USER_WEDDING_USER_ID"
    add_foreign_key "user_wedding", "wedding", primary_key: "wedding_id", name: "FK_USER_WEDDING_WEDDING_ID"

    create_table :wedding, primary_key: 'wedding_id' do |t|
      t.boolean :shell_flag, default: false
    end

    create_table :pen_collections do |t|
      t.timestamps null: true
    end

    create_table :pens do |t|
      t.string :color
      t.integer :pen_collection_id
    end

    create_table :products do |t|
      t.string :name
      t.float :price
      t.integer :store_id
      t.text :settings
      t.timestamps null: true
      t.actable
    end

    create_table :payments do |t|
      t.references :payable, polymorphic: true
      t.timestamps null: true
    end

    create_table :stores do |t|
      t.string :name
      t.timestamps null: true
    end

    create_table :buyers do |t|
      t.integer :product_id
    end

    create_table :pen_caps do |t|
      t.integer :pen_id
    end

    create_table :inventory_pen_lids do |t|
      t.string :color
    end

    create_table :inventory_product_features do |t|
      t.string :name
      t.float :price
      t.actable index: { name: 'index_inventory_product_features_on_actable' }
    end
  end
end

initialize_schema
