from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1WorkItemsSearchResponse200DataItem")


@_attrs_define
class GetV1WorkItemsSearchResponse200DataItem:
    """
    Attributes:
        id (str):
        project_id (str):
        project_name (str): the OWNING board’s name. A result list spanning boards is unreadable without it, and the
            client cannot join it itself — the boards a search reaches are exactly the ones it may not have loaded.
        item_key (str): the rendered key (`ADH-42`) — already joined from the board’s prefix, because a hit crossing
            boards crosses prefixes too.
        title (str):
        status_id (str):
        updated (int): Unix timestamp, in seconds.
        snippet (str): a plain-text excerpt of the DESCRIPTION (ts_headline, no markup). Empty-ish for a title-only or
            key hit, where the title is already the answer.
        rank (float): ts_rank over title (weight A) and description (weight B).
        object_ (Literal['work_item'] | Unset):
    """

    id: str
    project_id: str
    project_name: str
    item_key: str
    title: str
    status_id: str
    updated: int
    snippet: str
    rank: float
    object_: Literal["work_item"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        project_id = self.project_id

        project_name = self.project_name

        item_key = self.item_key

        title = self.title

        status_id = self.status_id

        updated = self.updated

        snippet = self.snippet

        rank = self.rank

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "project_id": project_id,
                "project_name": project_name,
                "item_key": item_key,
                "title": title,
                "status_id": status_id,
                "updated": updated,
                "snippet": snippet,
                "rank": rank,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        project_id = d.pop("project_id")

        project_name = d.pop("project_name")

        item_key = d.pop("item_key")

        title = d.pop("title")

        status_id = d.pop("status_id")

        updated = d.pop("updated")

        snippet = d.pop("snippet")

        rank = d.pop("rank")

        object_ = cast(Literal["work_item"] | Unset, d.pop("object", UNSET))
        if object_ != "work_item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'work_item', got '{object_}'")

        get_v1_work_items_search_response_200_data_item = cls(
            id=id,
            project_id=project_id,
            project_name=project_name,
            item_key=item_key,
            title=title,
            status_id=status_id,
            updated=updated,
            snippet=snippet,
            rank=rank,
            object_=object_,
        )

        get_v1_work_items_search_response_200_data_item.additional_properties = d
        return get_v1_work_items_search_response_200_data_item

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
