# frozen_string_literal: true

module Decidim
  module Members
    class MemberCollectionPresenter < Rectify::Presenter
      attribute :organization, Decidim::Organization
      attribute :page, Integer
      attribute :query, String

      def count
        unsorted_org_members.count
      end

      def render_pagination
        paginate collection, theme: "decidim"
      end

      def render_current_page
        render collection: decorated_members, partial: 'user'
      end

      private


      def collection
        @collection ||= org_members.page(page).per(12)
      end

      def decorated_members
        collection.map{ |m|
          ::Decidim::UserPresenter.new(m)
        }
      end

      def unsorted_org_members
        @org_members ||= begin
          scope = OrganizationMembers.new(organization).query
          if query.present?
            # scope = FilteredMembers.for(query, scope)
            scope = Decidim::Members::User.search_by_full_name(query)
          end
          scope
        end
      end

      def org_members
        if query.present?
          session[:members_ordering] = nil
          users = Decidim::User.table_name
          unsorted_org_members
          # unsorted_org_members.
          #   select("#{users}.*, ts_rank(#{users}.tsv, query, 1|32) as score").
          #   order('score ASC')
        else
          unsorted_org_members.reorder Hash[[session_ordering]]
        end
      end

      def session_ordering
        session[:members_ordering] ||= [[:id, :name, :email], [:asc, :desc]].map(&:sample)
      end

    end
  end
end
