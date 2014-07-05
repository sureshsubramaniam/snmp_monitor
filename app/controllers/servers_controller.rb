class ServersController < ApplicationController
  before_action :load_server
  before_action :authenticate_user!

  include MonitorTool
  include GraphTool

  def index
    @servers = current_user.servers
  end

  def show
    snmp_init( @server.ip_address, @server.community )

    load_average = get_load_average
    if load_average.nil?
      @load_average = nil
      @power_usage = nil
    else
      load_average *= 100
      @load_average = usage_graph( 'LoadAverage',  "#{sprintf( '%.2f', load_average )}%", load_average, '#da4f49' )
      power_usage = @server.cpu_tdp / @server.max_cpu_core * @server.assign_cpu_core * load_average / 100
      @power_usage = usage_graph( 'Power', "#{sprintf( '%.2f', power_usage )}W", power_usage / @server.cpu_tdp * 100, '#faa732' )
    end

    memory_usage = get_memory_usage
    if memory_usage.nil?
      @memory_usage = nil
    else
      memory_usage *= 100
      @memory_usage = usage_graph( 'Memory',  "#{sprintf( '%.2f', memory_usage )}%", memory_usage, '#5bb75b' )
    end
  end

  def new
    render :show_modal_form
  end

  def create
    @server = current_user.servers.create( server_params )
    @result = @server.save
    @server = nil unless @result
    flash[:notice] = '登録しました。' if @result
  end

  def edit
    render :show_modal_form
  end

  def update
    @result = @server.update( server_params )
    @server = nil unless @result
    flash[:notice] = '更新しました。' if @result
  end

  def delete
    render :show_modal_delete
  end

  def destroy
    @result = @server.destroy
    @server = nil unless @result
    flash[:notice] = '削除しました。' if @result
    flash[:alert] = '削除できませんでした。' unless @result
    render :reload
  end

  private

  def load_server
    @server = Server.id_is( params[:id] ) if params[:id]
  end

  def server_params
    params.require( :server ).permit( :ip_address, :community, :max_cpu_core, :assign_cpu_core, :cpu_tdp )
  end
end
