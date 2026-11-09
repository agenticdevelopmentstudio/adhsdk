from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_shipr_connections_by_id_repositories_refresh_response_200_repositories_item import (
        PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200RepositoriesItem,
    )


T = TypeVar("T", bound="PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200")


@_attrs_define
class PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200:
    """
    Attributes:
        repositories (list[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200RepositoriesItem]):
        read_at (datetime.datetime): When GitHub last said this. The picker shows a stored list immediately and
            refreshes behind it, so the list on screen can be older than the request that returned it — this is how a caller
            can say so instead of implying it is current.
        object_ (Literal['repository'] | Unset):
    """

    repositories: list[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200RepositoriesItem]
    read_at: datetime.datetime
    object_: Literal["repository"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        repositories = []
        for repositories_item_data in self.repositories:
            repositories_item = repositories_item_data.to_dict()
            repositories.append(repositories_item)

        read_at = self.read_at.isoformat()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "repositories": repositories,
                "read_at": read_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_shipr_connections_by_id_repositories_refresh_response_200_repositories_item import (
            PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200RepositoriesItem,
        )

        d = dict(src_dict)
        repositories = []
        _repositories = d.pop("repositories")
        for repositories_item_data in _repositories:
            repositories_item = (
                PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200RepositoriesItem.from_dict(
                    repositories_item_data
                )
            )

            repositories.append(repositories_item)

        read_at = datetime.datetime.fromisoformat(d.pop("read_at"))

        object_ = cast(Literal["repository"] | Unset, d.pop("object", UNSET))
        if object_ != "repository" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'repository', got '{object_}'")

        post_v1_shipr_connections_by_id_repositories_refresh_response_200 = cls(
            repositories=repositories,
            read_at=read_at,
            object_=object_,
        )

        post_v1_shipr_connections_by_id_repositories_refresh_response_200.additional_properties = d
        return post_v1_shipr_connections_by_id_repositories_refresh_response_200

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
