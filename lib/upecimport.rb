require 'csv'

class UPeCImport

  USER_ID = 1
  COLORS = [
    'BF1E2E', 
    'F1592A', 
    'F7941D', 
    '9EB83B', 
    '3AB54A', 
    '12A89D', 
    '25AAE2', 
    '0E76BD', 
    '652D90', 
    '92278F', 
    'ED207B', 
    '8C6238'
  ]

  def initialize(filename={})
    raw = CSV.read(filename)
    # Only delete DB on first run
    delete_db if Topic.count < 20
    process_all raw
  end

  def delete_db 
    # Clean all DDBB
    Topic.delete_all
    Post.delete_all
    Category.delete_all
  end

  def get_category_name category_name
    # Error on categories with more than 50 characters, changing names...
    case category_name
    when "Títol: 1. Un nou model econòmic i ecològic basat en el bé comú"
      "Un nou model econòmic"
    when "Títol: 2. Un nou model de benestar per una societat justa i igualitària"
      "Un nou model de bienestar"
    when "Títol: 3. Un país fratern i sobirà en tots els àmbits"
      "Un país fratern"
    when "Títol: 4. Una revolució democràtica i feminista"
      "Una revolució democràtica"
    when "Títol: 5. Un país inclusiu on tothom tingui cabuda"
      "Un plaís inclusiu"
    when "Títol: 6. Un projecte de país des de tots els territoris"
      "Un projecte de país"
    end
  end

  def create_category category_name
    # Create category given a name
    category = Category.find_or_create_by(
      name: category_name,
      color: COLORS.sample,
      user_id: USER_ID
    )
  end

  def create_subcategory subcategory_name, category
    # Create subcategory given a name and a category object
    subcategory = Category.find_or_create_by(
      name: subcategory_name, 
      parent_category: category, 
      color: COLORS.pop,
      user_id: USER_ID
    )
  end

  def create_topic topic_title, topic_body, subcategory
    # Create a Topic and a first Post (required by Discourse)
    topic = Topic.new(
      title: topic_title, 
      category: subcategory, 
      user_id: USER_ID
    )
    # Doesn't like titles like "Diagnosi", too little chars :/ 
    topic.save(validate: false)
    post = Post.create(
      raw: topic_body, 
      user_id: USER_ID, 
      topic: topic
    ) 
  end

  def process_all raw
    # Create category from first row first line

    #category_name = raw[0][0]   
    category_name = get_category_name raw[0][0]
    puts "Creating Category ... " + category_name
    category = create_category category_name

    (1..100).each do |column|
      # Create or find this subcategory by name
      subcategory_name = raw[2][column]
      unless subcategory_name.nil?
        puts "Creating Subcategory ... " + subcategory_name
        subcategory = create_subcategory subcategory_name, category
        (3..100).each do |line|
          # line = 3
          # Create topics on subcategory 
          unless raw[line].nil? or raw[line][column].nil?
            topic_title = raw[line][column].split("\n")[0]
            topic_body = raw[line][column].split("\n")[1..-1].join("\n\n")
            puts "Creating Topic => " + topic_title
            create_topic topic_title, topic_body, subcategory
          end
        end
      end
    end
  end

end
