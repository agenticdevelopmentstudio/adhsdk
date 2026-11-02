from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.search_discussion_post_result import SearchDiscussionPostResult
    from ..models.search_discussion_topic_result import SearchDiscussionTopicResult


T = TypeVar("T", bound="GetSearchDiscussionsResponse200")


@_attrs_define
class GetSearchDiscussionsResponse200:
    """
    Attributes:
        topics (list[SearchDiscussionTopicResult]):
        posts (list[SearchDiscussionPostResult]):
        page (int):
        page_size (int):
        topics_has_more (bool):
        posts_has_more (bool):
    """

    topics: list[SearchDiscussionTopicResult]
    posts: list[SearchDiscussionPostResult]
    page: int
    page_size: int
    topics_has_more: bool
    posts_has_more: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        topics = []
        for topics_item_data in self.topics:
            topics_item = topics_item_data.to_dict()
            topics.append(topics_item)

        posts = []
        for posts_item_data in self.posts:
            posts_item = posts_item_data.to_dict()
            posts.append(posts_item)

        page = self.page

        page_size = self.page_size

        topics_has_more = self.topics_has_more

        posts_has_more = self.posts_has_more

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "topics": topics,
                "posts": posts,
                "page": page,
                "pageSize": page_size,
                "topicsHasMore": topics_has_more,
                "postsHasMore": posts_has_more,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.search_discussion_post_result import (
            SearchDiscussionPostResult,
        )
        from ..models.search_discussion_topic_result import (
            SearchDiscussionTopicResult,
        )

        d = dict(src_dict)
        topics = []
        _topics = d.pop("topics")
        for topics_item_data in _topics:
            topics_item = SearchDiscussionTopicResult.from_dict(topics_item_data)

            topics.append(topics_item)

        posts = []
        _posts = d.pop("posts")
        for posts_item_data in _posts:
            posts_item = SearchDiscussionPostResult.from_dict(posts_item_data)

            posts.append(posts_item)

        page = d.pop("page")

        page_size = d.pop("pageSize")

        topics_has_more = d.pop("topicsHasMore")

        posts_has_more = d.pop("postsHasMore")

        get_search_discussions_response_200 = cls(
            topics=topics,
            posts=posts,
            page=page,
            page_size=page_size,
            topics_has_more=topics_has_more,
            posts_has_more=posts_has_more,
        )

        get_search_discussions_response_200.additional_properties = d
        return get_search_discussions_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
