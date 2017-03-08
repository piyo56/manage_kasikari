class KasikarisController < ApplicationController
  before_action :set_kasikari,   only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update, :destroy]
  before_action :correct_item,   only: [:new_kari]

  def index
    @kasikaris = Kasikari.paginate(page: params[:page])
  end

  def show
  end

  def new
    @kasikari = Kasikari.new
  end

  def new_kari
    @from_user = User.find_by(id: @item.owner.id)
    @to_user   = current_user
    @kasikari = Kasikari.new(
      item_id:      @item.id,
      from_user_id: @from_user.id,
      to_user_id:   @to_user.id,
    )

    render 'new_with_item'
  end

  def create
    @kasikari = Kasikari.new(kasikari_params)

    if @kasikari.save
      flash[:success] = "貸し借りを登録しました"
      redirect_to @kasikari
    else
      redirect_to new_kasikari_path
    end
  end

  def edit
  end

  def update
    if @kasikari.update_attributes(kasikari_params)
      @kasikari.item.update_attributes!(available: !@kasikari.ongoing?)
      flash[:success] = "貸し借りを更新しました"
      respond_to do |format|
        format.html { redirect_to @kasikari }
        format.js
      end
    else
      render 'edit'
    end
  end

  def destroy
    @kasikari.destroy
    @kasikari.item.update_attributes!(available: true)
    flash[:success] = "貸し借りを削除しました。"
    redirect_to user_path(current_user)
  end

  private

  def set_kasikari
    @kasikari = Kasikari.find(params[:id])
  end

  def kasikari_params
    param = params.require(:kasikari)

    param.permit(
      :item_id,
      :from_user_id,
      :to_user_id,
      :start_date,
      :end_date,
      :status,
    )
  end

  # 正しいユーザーかどうか確認
  def correct_user
    friends   = current_user.friends
    from_user = @kasikari.from_user
    to_user   = @kasikari.to_user

    if ![from_user, to_user].include?(current_user)
      flash[:danger] = "貸し借りにあなたが含まれていません"
      redirect_to new_kasikari_path
    elsif from_user == current_user && to_user == current_user
      flash[:danger] = "貸し借りをするユーザーの組み合わせが無効です"
      redirect_to new_kasikari_path
    elsif !friends.include?(from_user) && !friends.include?(to_user)
      flash[:danger] = "友達でないユーザーとの貸し借りはできません"
      redirect_to new_kasikari_path
    end
  end

  def correct_item
    @item = Item.find(params[:id])

    if current_user?(@item.owner)
      redirect_to root_path
    elsif !current_user.friend_with?(@item.owner)
      redirect_to root_path
    end
  end
end
